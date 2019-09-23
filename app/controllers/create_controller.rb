require 'net/http'
require 'uri'
require 'json'

class CreateController < ApplicationController
  attr_accessor :repo

  def initialize()
    uri = URI.parse('https://registry.ie.u-ryukyu.ac.jp/v2/_catalog')
    json = Net::HTTP.get(uri)
    result = JSON.parse(json)
    @repo = result['repositories']

    super
  end

  def new
    @create = Create.new
  end

  def state
    @create = Create.new(create_params)

    image = params[:image]
    name = params[:name]
    port = params[:port]

    if @create.valid?
      client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))

      resource = K8s::Resource.new(
        apiVersion: 'apps/v1',
        kind: 'Deployment',
        metadata: {
          name: "#{name}",
          namespace: 'student'
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
      @create = client.api('apps/v1').resource('deployments', namespace: 'student').create_resource(resource)
      @expose = system("kubectl --namespace=student expose --type NodePort --port #{port} deployment #{name}")
    else
      render 'new'
    end

  end

  private
  def create_params
    params.require(:create).permit(:image, :name, :port)
  end

end
