# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    super

    if resource.sign_in_count == 1
      client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
      #client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "local_k8s_config.yml")))

      namespaces_list = client.api('v1').resource('namespaces').list
      namespaces = []
      namespaces_list.each do |namespace|
        namespaces.push(namespace.metadata.name)
      end
      count = namespaces.select{|namespace| namespace == current_user.username}
      if count.count == 0
        system("kubectl create namespace #{current_user.username}")
      end

      config = YAML.load_file(File.join(Rails.root, "config", "ldap.yml"))['admin']
      ldap = Net::LDAP.new(host: config['host'], port: config['port'], base: config['base'],
        auth: { :method => :simple,
          :username => config['admin_user'],
          :password => config['admin_password'] })
      raise 'bind failed' unless ldap.bind
      entries = {}
      ldap.open { |conn|
        filter = Net::LDAP::Filter.eq(config['attribute'], current_user.username)
        conn.search(filter: filter) do |entry|
          entry.each do |field, value|
            entries[field] = value
          end
        end
      }

      count = entries[:memberuid].select{|id| id == current_user.username}
      if count.count == 1
        user = User.where(:username => current_user.username).first
        user.is_admin = true
        user.save
      end
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
