class Admin::DeployController < ApplicationController
  before_action :authenticate_user!
  before_action :if_not_admin

  # すべてのdeployの一覧を表示
  def index
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))

    # deployの一覧に表示させたくないnamespace(ユーザ用では無いnamespace)
    exclude_namespace = ["default", "dex", "ingress-nginx",
      "kube-node-lease", "kube-public", "kube-system",
      "metallb-system", "student", "test", "kubernetes-dashboard"]

    # k8sのAPIを叩いて、ユーザ用のnamesapceを取得
    namespaces = []
    namespace_list = client.api('v1').resource('namespaces').list
    namespace_list.each do |namespace|
      hash = namespace.to_h
      name = hash.dig(:metadata, :name)
      !exclude_namespace.include?(name) && namespaces.push(name)
    end

    # k8sのAPIを叩いて、podの一覧を作成
    pods = {}
    namespaces.each do |namesapce|
      if !pods[namesapce]
        pods[namesapce] = []
      end
      pods_list = client.api('v1').resource('pods', namespace: namesapce).list
      pods_list.each do |pod|
        hash = pod.to_h
        name = hash.dig(:metadata, :labels, :app)
        space = hash.dig(:metadata, :namespace)
        image = hash.dig(:spec, :containers, 0, :image)
        port = "#{hash.dig(:spec, :containers, 0, :ports, 0, :protocol)}/#{hash.dig(:spec, :containers, 0, :ports, 0, :containerPort)}"
        pods[space].push({:name => name , :image => image, :port => port})
      end
    end

    # railsのデータベースにある取得したpodの情報を取得
    @merged = []
    pods.each do |key,value|
      if !value.empty?
        value.each do |hash|
          name = hash.dig(:name)
          image = hash.dig(:image)
          port = hash.dig(:port)
          deploy = Create.where(deploy: name, space: key).first
          if deploy == nil
            is_delete = nil
            is_recognize = nil
            id = nil
          else
            is_delete = deploy.is_delete
            is_recognize = deploy.is_recognize
            id = deploy.id
          end
          @merged.push([name, key, image, port, is_delete, is_recognize, id])
        end
      end
    end

    @create = Create.new
  end

  def edit
    @create = Create.find(params[:id])
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
    hash = client.api('apps/v1').resource('deployments', namespace: @create.space).get(@create.deploy).to_h
    image = hash.dig(:spec, :template, :spec, :containers, 0, :image)
    port = hash.dig(:spec, :template, :spec, :containers, 0, :ports, 0, :containerPort)
    request_cpu = hash.dig(:spec, :template, :spec, :containers, 0, :resources, :requests, :cpu).slice!(/([0-9]+)m/,1)
    limit_cpu = hash.dig(:spec, :template, :spec, :containers, 0, :resources, :limits, :cpu).slice!(/([0-9]+)m/,1)
    request_memory = hash.dig(:spec, :template, :spec, :containers, 0, :resources, :requests, :memory).slice!(/([0-9]+)Mi/,1)
    limit_memory = hash.dig(:spec, :template, :spec, :containers, 0, :resources, :limits, :memory).slice!(/([0-9]+)Mi/,1)
    @detail = [image, port, request_cpu, limit_cpu, request_memory, limit_memory]
  end

  def update
    create = Create.find(params[:id].to_i)
    create.name = params[:create][:deployment]
    create.port = params[:create][:port]
    create.image = params[:create][:image]
    create.request_cpu = params[:create][:request_cpu]
    create.limit_cpu = params[:create][:limit_cpu]
    create.request_memory = params[:create][:request_memory]
    create.limit_memory = params[:create][:limit_memory]
    if params[:create][:is_recognize] == "1"
      create.is_recognize = true
    else
      create.is_recognize = false
    end
    create.save

    redirect_to "/admin/deploy"
  end

  private

  # adminユーザかどうか
  def if_not_admin
    if current_user.is_admin == false
      redirect_to root_path
    end
  end
end
