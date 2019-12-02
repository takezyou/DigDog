require 'net/http'
require 'uri'
require 'json'

class CreateController < ApplicationController
  before_action :authenticate_user!
  attr_accessor :repo, :client

  def initialize()
    token = get_token()
    @repo = get_repo(token)

    super
  end

  def new
    if @error != nil
      render 'error', group: @error
    end

    if @repo == nil
      token = get_token()
      @repo = get_repo(token)
    end

    @create = Create.new
  end

  def error
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
