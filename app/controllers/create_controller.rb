require 'net/http'
require 'uri'
require 'json'

class CreateController < ApplicationController
  before_action :authenticate_user!
  attr_accessor :repo, :client

  def initialize()
    token = get_token()
    uri = URI.parse('https://registry.ie.u-ryukyu.ac.jp/v2/_catalog')

    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "bearer #{token}"

    begin
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.open_timeout = 5
        http.read_timeout = 10
        http.request(req)
      end

      case response
      when Net::HTTPSuccess # 2xx系
        result = JSON.parse(response.body)
        @repo = result['repositories']
      else
        @error = "HTTP ERROR: code=#{response.code} message=#{response.message}"
      end
    rescue IOError => e # 既にセッションが開始している場合
      @error = e.message
    rescue TimeoutError => e  # タイムアウト時
      @error = e.message
    rescue JSON::ParserError => e # JSONのパースエラー
      @error = e.message
    rescue => e # その他
      @error = e.message
    end

    super
  end

  def new
    if @error != nil
      render 'error', group: @error
    end

    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
    #@client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "local_k8s_config.yml")))
    pods = client.api('v1').resource('pods', namespace: current_user.username).list
    if pods.count > 2
      @error = "Podの作成数の上限を超えています。(上限:3、現在:#{pods.count})"
      render 'error', group: @error
    end

    @create = Create.new
  end

  def error
  end

  def state
    @create = Create.new(create_params)

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
      end
    else
      render 'new'
    end

  end

  private
  def create_params
    params.require(:create).permit(:image, :name, :port)
  end

  def get_token
    uri = URI('https://gitlab.ie.u-ryukyu.ac.jp/jwt/auth?service=container_registry&scope=registry:catalog:*')
    req = Net::HTTP::Get.new(uri)
    config = YAML.load_file(File.join(Rails.root, "config", "password.yml"))['repository']
    req.basic_auth(config['username'], config['password'])
    res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') { |http|
      http.request(req)
    }
    if res.is_a?(Net::HTTPSuccess)
      token = JSON.parse(res.body)['token']
      return token
    else
      abort "get access_token failed: body=" + res.body
    end
  end

end
