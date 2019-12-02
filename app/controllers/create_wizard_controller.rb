require 'net/http'
require 'uri'
require 'json'

class CreateWizardController < ApplicationController
  before_action :authenticate_user!
  attr_accessor :repo

  def initialize()
    token = get_token()
    @repo = get_repo(token)

    super
  end

  def index
    @create = Create.new
    @create.forms.build
    if @repo == nil
      token = get_token()
      @repo = get_repo(token)
    end
  end

  def step2
    @create = Create.new
    @create.forms.build
    parameter = step2_params[:forms_attributes].to_hash
    session[:count] = parameter.length
    parameter.map.with_index { |attribute, index|
       session["image-#{index}".to_sym] = attribute[1]["image"]
    }

    @result = []
    @conflict = []
  end

  def step3
    @create = Create.new
    @create.forms.build
    count = session[:count].to_i
    parameter = step3_params.to_hash
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
    deployments = []
    deployments_list = client.api('apps/v1').resource('deployments', namespace: current_user.username).list
    deployments_list.each do |deploy|
      hash = deploy.to_h
      name = hash.dig(:metadata, :name)
      deployments.push(name)
    end

    attributes = []
    @conflict = []
    conflict_flag = false
    parameter.map.with_index{ |attribute, index|
      if !deployments.include?(attribute[1]["name"])
        session["name-#{index}".to_sym] = attribute[1]["name"]
        session["port-#{index}".to_sym] = attribute[1]["port"]
        attributes.append({
          "image" => session["image-#{index}".to_sym],
          "name" => session["name-#{index}".to_sym],
          "port" => session["port-#{index}".to_sym]
        })
      else
        @conflict.push(attribute[1]["name"])
        conflict_flag = true
      end
    }
    if conflict_flag == true
      render 'create_wizard/step2', group: @conflict
    else
      temp = attributes.map do |value|
        Create.new(value)
      end
      flag = false
      @results = {}
      temp.map.with_index do |tmp, index|
        if !tmp.valid?
          flag = true
          @results[index] = tmp.errors
        end
      end
      if flag == true
        render 'create_wizard/step2', group: @results
      else
        render 'create_wizard/step3'
      end
    end
  end

  def done
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
    parameters = step3_params.to_hash
    parameters.each do |parameter|
      name = parameter[1]["name"]
      image = parameter[1]["image"]
      port = parameter[1]["port"]
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

          create = Create.new(
            image: image,
            name: name,
            port: port,
            deploy: name,
            space: current_user.username,
            create_time: Time.now,
            is_delete: true,
            is_recognize: false
          )
          create.save
        rescue K8s::Error::Conflict => e
        end
      rescue K8s::Error::Conflict => e
      end
    end
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

  def get_repo(token)
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
        repo = result['repositories']
        return repo
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
  end

  private
  def step2_params
    params.require(:create).permit(forms_attributes: [:image, :_destroy])
  end

  def step3_params
    params.require(:create).permit!
  end
end
