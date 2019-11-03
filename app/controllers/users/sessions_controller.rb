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
      current_username = current_user.username

      namespaces_list = client.api('v1').resource('namespaces').list
      namespaces = []
      namespaces_list.each do |namespace|
        namespaces.push(namespace.metadata.name)
      end
      count = namespaces.select{|namespace| namespace == current_username}
      if count.count == 0
        create_namespace(client, current_username)
        create_rbac(client, current_username)
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

  private

  def create_namespace(client, current_username)
    resource = K8s::Resource.new(
      apiVersion: 'v1',
      kind: 'Namespace',
      metadata: {
        name: "#{current_username}",
        labels: {
          name: "#{current_username}"
        }
      }
    )
    client.api('v1').resource('namespaces').create_resource(resource)
  end

  def create_rbac(client, current_username)
    serviceaccount = K8s::Resource.new(
      apiVersion: 'v1',
      kind: 'ServiceAccount',
      metadata: {
        name: "#{current_username}",
        namespace: "#{current_username}"
      }
    )
    client.api('v1').resource('serviceaccounts').create_resource(serviceaccount)

    role = K8s::Resource.new(
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'Role',
      metadata: {
        namespace: "#{current_username}",
        name: "#{current_username}"
      },
      rules: [
        {
          apiGroups: [""],
          resources: ["pods"],
          verbs: ["get", "watch", "list"]
        }
      ]
    )
    client.api('rbac.authorization.k8s.io/v1').resource('roles').create_resource(role)

    rolebinding = K8s::Resource.new(
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'RoleBinding',
      metadata: {
        namespace: "#{current_username}",
        name: "#{current_username}-rolebinding"
      },
      roleRef: {
         apiGroup: 'rbac.authorization.k8s.io',
         kind: 'Role',
         name: "#{current_username}"
      },
      subjects: [
        {
          apiGroups: "",
          kind: 'ServiceAccount',
          name: "#{current_username}",
          namespace: "#{current_username}"
        }
      ]
    )
    client.api('rbac.authorization.k8s.io/v1').resource('rolebindings').create_resource(rolebinding)
  end
end
