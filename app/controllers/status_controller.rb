class StatusController < ApplicationController
  before_action :authenticate_user!

  def show
    current_username = current_user.username
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))

    pods_list = client.api('v1').resource('pods', namespace: current_user.username).list
    @pods = []
    pods_list.each do |pod|
      hash = pod.to_h
      name = "#{hash.dig(:spec, :containers, 0, :name)}(#{hash.dig(:metadata, :name)})"
      image = "#{hash.dig(:spec, :containers, 0, :image)}"
      image.slice!(0..26)
      port = "#{hash.dig(:spec, :containers, 0, :ports, 0, :containerPort)}"
      phase = hash.dig(:status,:phase)
      symbol = hash.dig(:status, :containerStatuses, 0, :state).keys[0].to_s
      reason = symbol == "waiting" ? hash.dig(:status, :containerStatuses, 0, :state, :waiting, :reason) : nil
      @pods.push({
        :name => name,
        :image => image,
        :port => port,
        :phase => phase,
        :state => symbol,
        :reason => reason
        })
    end

    deployments_list = client.api('apps/v1').resource('deployments', namespace: current_user.username).list
    @deployments = []
    deployments_list.each do |deployment|
      hash = deployment.to_h
      name = hash.dig(:metadata, :name)
      total = hash.dig(:status, :replicas)
      available = hash.dig(:status, :availableReplicas).nil? ? 0 : hash.dig(:status, :availableReplicas)
      unavailable = hash.dig(:status, :unavailableReplicas).nil? ? 0 : hash.dig(:status, :unavailableReplicas)
      reason = hash.dig(:status,:conditions).reverse[0].dig(:reason)
      db = Create.where(:deploy => name, :space => current_user.username).first
      if db.nil?
        delete = nil
        recognize = nil
      else
        delete = db.is_delete
        recognize = db.is_recognize
      end
      @deployments.push({
        :name => name,
        :ready => "#{available.to_s}/#{total.to_s}",
        :available => "#{available.to_s}",
        :reason => reason,
        :is_delete => delete,
        :is_recognize => recognize
        })
    end

    domain_list = client.api('networking.k8s.io/v1beta1').resource('ingresses', namespace: current_user.username).list
    @domains = []
    domain_list.each do |domain|
      hash = domain.to_h
      pod_name = hash.dig(:spec, :rules)[0].dig(:http, :paths)[0].dig(:backend, :serviceName)
      name = hash.dig(:metadata, :name)
      puts name
      hostname = hash.dig(:spec, :rules)[0].dig(:host)

      @domains.push({
                            :pod_name => pod_name,
                            :name => name,
                            :hostname => hostname,
                        })
    end
  end

  def user
    config = YAML.load_file(File.join(Rails.root, "config", "ldap.yml"))['development']
    ldap = Net::LDAP.new(host: config['host'], port: config['port'], base: config['base'],
                         auth: { :method => :simple,
                                 :username => config['admin_user'],
                                 :password => config['admin_password'] })
    raise 'bind failed' unless ldap.bind
    @entries = {}
    ldap.open { |conn|
      filter = Net::LDAP::Filter.eq(config['attribute'], current_user.username)
      conn.search(filter: filter) do |entry|
        entry.each do |field, value|
          @entries[field] = value
        end
      end
    }
  end
end
