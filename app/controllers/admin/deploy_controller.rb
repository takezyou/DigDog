class Admin::DeployController < ApplicationController
  before_action :authenticate_user!
  before_action :if_not_admin

  # すべてのdeployの一覧を表示
  def index
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))

    # deployの一覧に表示させたくないnamespace(ユーザ用では無いnamespace)
    exclude_namespace = ["default", "dex", "ingress-nginx",
      "kube-node-lease", "kube-public", "kube-system",
      "metallb-system", "student", "test"]

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

    {"e165755"=>[
        {:name=>"test", :image=>"registry.ie.u-ryukyu.ac.jp/e175706/jupyter", :port=>"TCP/8888"},
        {:name=>"test1", :image=>"registry.ie.u-ryukyu.ac.jp/e175706/docker-test", :port=>"TCP/12345"}
      ],
     "e175706"=>[
        {:name=>"test13", :image=>"registry.ie.u-ryukyu.ac.jp/e175706/jupyter", :port=>"TCP/8888"},
        {:name=>"test404", :image=>"registry.ie.u-ryukyu.ac.jp/e175706/jupyter", :port=>"TCP/8888"},
        {:name=>"test5", :image=>"registry.ie.u-ryukyu.ac.jp/e175706/jupyter", :port=>"TCP/8888"},
        {:name=>"test9", :image=>"registry.ie.u-ryukyu.ac.jp/e175706/jupyter", :port=>"TCP/8888"}
      ],
     "hoge"=>[],
     "k188575"=>[]
   }

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
          else
            is_delete = deploy.is_delete
            is_recognize = deploy.is_recognize
          end
          @merged.push([name, key, image, port, is_delete, is_recognize])
        end
      end
    end

    @create = Create.new
  end

  private

  # adminユーザかどうか
  def if_not_admin
    if current_user.is_admin == false
      redirect_to root_path
    end
  end
end
