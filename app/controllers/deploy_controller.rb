class DeployController < ApplicationController
  before_action :authenticate_user!

  #デプロイの作成
  def create
    @create = Create.new(create_params)

    if @repo == nil
      create = CreateController.new
      token = create.get_token()
      @repo = create.get_repo(token)
    end

    if @create.valid?
      image = create_params[:image]
      name = create_params[:name]
      port = create_params[:port]
      request_memory = create_params[:request_memory]
      limit_memory = create_params[:limit_memory]
      request_cpu = create_params[:request_cpu]
      limit_cpu = create_params[:limit_cpu]

      @create.deploy = name
      @create.space = current_user.username
      @create.create_time = Time.now
      @create.is_delete = true
      @create.is_recognize = false

      client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))

      resource = K8s::Resource.new(
        apiVersion: 'apps/v1',
        kind: 'Deployment',
        metadata: {
          name: "#{name}",
          namespace: current_user.username
        },
        spec: {
          replicas: 1,
          selector: {
            matchLabels: {
              app: "#{name}"
            }
          },
          strategy: {
            rollingUpdate: {
              maxSurge: "50%",
              maxUnavailable: "0%"
            }
          },
          template: {
            metadata: {
              labels: {
                app: "#{name}"
              }
            },
            spec: {
              containers: [
                name: "#{name}",
                image: "registry.ie.u-ryukyu.ac.jp/#{image}",
                resources: {
                  requests: {
                    memory: "#{request_memory}Mi",
                    cpu: "#{request_cpu}"
                  },
                  limits: {
                    memory: "#{limit_memory}Mi",
                    cpu: "#{limit_cpu}"
                  }
                },
                ports: [
                  containerPort: "#{port}".to_i
                ]
              ]
            }
          }
        }
      )

      begin
        client.api('apps/v1').resource('deployments', namespace: current_user.username).create_resource(resource)
        begin
          expose_resource = K8s::Resource.new(
            kind: 'Service',
            apiVersion: 'v1',
            metadata: {
              namespace: current_user.username,
              name: "#{name}"
            },
            spec: {
              ports: [
                name: "#{name}",
                port: "#{port}".to_i,
                protocol: "TCP"
              ],
              type: "NodePort",
              selector: {
                app: "#{name}"
              }
            }
          )
          client.api('v1').resource('services').create_resource(expose_resource)
          @create.save

          text = "<ul><li>image: #{create_params[:image]}</li><li>name: #{create_params[:name]}</li><li>port: #{create_params[:port]}</li></ul>"
          flash.now[:success] = text

          render 'create/new', group: @repo
        rescue K8s::Error::Conflict => e
          conflict_message(name, @repo)
        end
      rescue K8s::Error::Conflict => e
        conflict_message(name, @repo)
      end
    else
      render 'create/new', group: @repo
    end
  end

  #デプロイの削除
  def delete
    deployment = params[:deployment]

    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
    begin
      client.api('apps/v1').resource('deployments', namespace: current_user.username).delete("#{deployment}")
      begin
        client.api('v1').resource('services', namespace: current_user.username).delete("#{deployment}")
        deploy = Create.where(:deploy => deployment, :space => current_user.username).first
        deploy.delete
      rescue K8s::Error => e
          render :text => e.message, :status => 500
      end
    rescue K8s::Error
      render :text => e.message, :status => 500
    end
  end

  #デプロイの除外申請
  def expand
    deployment = params[:deployment]

    deploy = Create.where(deploy: deployment, space: current_user.username)
    deploy.update_all(is_delete: false)
  end

  private
  def create_params
    params.require(:create).permit(:image, :name, :port, :request_memory, :limit_memory, :request_cpu, :limit_cpu)
  end

  def conflict_message(name, repo)
    text = "Conflictが発生しました<ul><li>Deployment \"#{name}\" は既に存在します</li></ul>"
    flash.now[:warning] = text

    render 'create/new', group: repo
  end
end
