class DomainController < ApplicationController
  before_action :authenticate_user!

  def create
    #デプロイの作成

    image = "e175706/jupyter"
    name = "testingress2"
    port = "8888"

    resource = K8s::Resource.new(
      apiVersion: 'networking.k8s.io/v1beta1',
      kind: 'Ingress',
      metadata: {
        name: "#{name}",
        namespace: "e175706",
        annotations: {
          "nginx.ingress.kubernetes.io/rewrite-target": '/$1'
        }
      },
      spec: {
        rules: [
          host: "#{name}.ns.ie.u-ryukyu.ac.jp",
          http: {
            paths: [
              path: '/',
              backend: {
                serviceName: "web",
                servicePort: 8080
              }
            ]
          }
        ]
      }
    )

    client = K8s::Client.config(
      K8s::Config.load_file(
        File.expand_path '~/SDN/DigDog/config/k8s_config.yml'
      )
    )

    client.api('networking.k8s.io/v1beta1').resource('ingresses', namespace: "e175706").create_resource(resource)
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
end

