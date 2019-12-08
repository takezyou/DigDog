class DomainController < ApplicationController
  before_action :authenticate_user!

  def new
    @domain = Domain.new()
    @deploy = get_deploy()
    @user = current_user.username
  end

  def create
    @domain = Domain.new(domain_params)
    @user = current_user.username

    if @deploy == nil
       @deploy = get_deploy()
    end

    if @domain.valid?
      name = domain_params[:name]
      port = domain_params[:port]
      svc = domain_params[:svc]

      client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))

      resource = K8s::Resource.new(
          apiVersion: 'networking.k8s.io/v1beta1',
          kind: 'Ingress',
          metadata: {
              name: "#{name}",
              namespace: current_user.username,
              annotations: {
                  "nginx.ingress.kubernetes.io/rewrite-target": '/'
              }
          },
          spec: {
              rules: [
                  host: "#{name}.ns.ie.u-ryukyu.ac.jp",
                  http: {
                      paths: [
                          path: '/',
                          backend: {
                              serviceName: "#{svc}",
                              servicePort: "#{port}".to_i
                          }
                      ]
                  }
              ]
          }
       )
       begin
         client.api('networking.k8s.io/v1beta1').resource('ingresses', namespace: current_user.username).create_resource(resource)

         flash.now[:success] = "ドメイン #{name}.ie.u-ryukyu.ac.jp を作成しました"
         render 'domain/new', group: @deploy
       rescue K8s::Error::Conflict => e
         flash.now[:conflict] = "ドメイン #{name}.ie.u-ryukyu.ac.jp は既に存在しています"
         render 'domain/new', group: @deploy
       end
    else
      render 'domain/new', group: @deploy
    end
  end

  def delete
    domain = params[:deployment]

    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
    begin
      client.api('networking.k8s.io/v1beta1').resource('ingresses', namespace: current_user.username).delete("#{domain}")
    rescue K8s::Error => e
      render :text => e.message, :status => 500
    end
  end

  def get_deploy_data
    deploy = params[:deployment]
    user = params[:current_user]
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
    begin
      deployment = client.api('apps/v1').resource('deployments', namespace: user).get(deploy).to_h
      name = deployment.dig(:metadata, :name)
      port = deployment.dig(:spec, :template, :spec, :containers, 0, :ports, 0, :containerPort)
      result = {:status => "Success", :current_user => user , :name => name, :port => port}
      render :json => result
    rescue K8s::Error => e
      result = {:status => "Error", :message => e.message}
      render :json => result
    end
  end

  private
  def domain_params
    params.require(:domain).permit(:name, :port, :svc)
  end

  def get_deploy
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
    deploy_list = client.api('apps/v1').resource('deployments', namespace: current_user.username).list
    deploys = []
    deploy_list.each do |deploy|
      hash = deploy.to_h
      name = hash.dig(:spec, :template, :spec, :containers, 0, :name)
      port = hash.dig(:spec, :template, :spec, :containers, 0, :ports, 0, :containerPort)
      deploys.push(name)
    end
    deploys
  end
end
