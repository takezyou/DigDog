class DomainController < ApplicationController
  before_action :authenticate_user!

  def new
    @domain = Domain.new()
  end

  def create
    name = domain_params[:name]
    port = domain_params[:port]
    svc = domain_params[:svc]

    p name
    p port
    p svc

    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))

    resource = K8s::Resource.new(
        apiVersion: 'networking.k8s.io/v1beta1',
        kind: 'Ingress',
        metadata: {
            name: "#{name}",
            namespace: current_user.username,
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
                            serviceName: "#{svc}",
                            servicePort: "#{port}".to_i
                        }
                    ]
                }
            ]
        }
     )
    client.api('networking.k8s.io/v1beta1').resource('ingresses', namespace: current_user.username).create_resource(resource)

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

  private
  def domain_params
    params.require(:domain).permit(:name, :port, :svc)
  end

end

