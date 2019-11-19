class Admin::ConsoleController < ApplicationController
  before_action :authenticate_user!
  before_action :if_not_admin

  def index

  end

  def pod
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
        name = hash.dig(:metadata, :name)
        space = hash.dig(:metadata, :namespace)
        image = hash.dig(:spec, :containers, 0, :image)
        port = "#{hash.dig(:spec, :containers, 0, :ports, 0, :protocol)}/#{hash.dig(:spec, :containers, 0, :ports, 0, :containerPort)}"
        pods[space].push({:name => name , :image => image, :port => port})
      end
    end

    @convert = []
    pods.each do |key,value|
      if !value.empty?
        value.each do |hash|
          name = hash.dig(:name)
          image = hash.dig(:image)
          port = hash.dig(:port)
          @convert.push([name, key, image, port])
        end
      end
    end
  end

  private
  def if_not_admin
    if current_user.is_admin == false
      redirect_to root_path
    end
  end
end
