class StatusController < ApplicationController
  before_action :authenticate_user!

  def show
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
    #client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "local_k8s_config.yml")))

    #@pods = client.api('v1').resource('pods', namespace: 'kube-system').list
    @pods = client.api('v1').resource('pods', namespace: 'student').list

    @deployments = client.api('apps/v1').resource('deployments', namespace: 'student').list
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
