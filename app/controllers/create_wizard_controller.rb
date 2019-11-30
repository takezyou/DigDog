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
    if @repo == nil
      token = get_token()
      @repo = get_repo(token)
    end
  end

  def step2
    @create = Create.new
    parameter = params[:create]
    session[:count] = parameter[:count]
    (parameter[:count].to_i).times { |num|
      session["image-#{num}".to_sym] = parameter["#{num}"][:image]
    }
    @result = []
  end

  def step3
    count = session[:count].to_i
    parameter = params[:create]
    attributes = []
    (count+1).times.map { |num|
      session["name-#{num}".to_sym] = parameter["#{num}"][:name]
      session["port-#{num}".to_sym] = parameter["#{num}"][:port]
      attributes.append({
          "image" => session["image-#{num}".to_sym],
          "name" => session["name-#{num}".to_sym],
          "port" => session["port-#{num}".to_sym]
      })
    }
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
    if flag = true
      render 'create_wizard/step2', group: @results
    else
      render 'create_wizard/step3'
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

end
