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

      @create.deploy = name
      @create.space = current_user.username
      @create.create_time = Time.now
      @create.is_delete = true
      @create.is_recognize = false

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
                ports: [
                  containerPort: "#{port}".to_i
                ]
              ]
            }
          }
        }
      )
      client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
      #@client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "local_k8s_config.yml")))

      client.api('apps/v1').resource('deployments', namespace: current_user.username).create_resource(resource)

      @expose = system("kubectl --namespace=#{current_user.username} expose --type NodePort --port #{port} deployment #{name}")

      if @expose
        @create.save

        text = "<ul><li>image: #{create_params[:image]}</li><li>name: #{create_params[:name]}</li><li>port: #{create_params[:port]}</li></ul>"
        flash.now[:success] = text

        render 'create/new', group: @repo
      end
    else
      render 'create/new', group: @repo
    end
  end

  #デプロイの削除
  def delete
    deployment = params[:deployment]

    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
    @deploy = client.api('apps/v1').resource('deployments', namespace: current_user.username).delete("#{deployment}")
    @service = system("kubectl --namespace=#{current_user.username} delete svc #{deployment}")

    if @service
      deploy = Create.where(:deploy => deployment, :space => current_user.username).first
      deploy.delete
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
    params.require(:create).permit(:image, :name, :port)
  end
end
