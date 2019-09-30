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
      current_username = cuurent_user.username

      namespaces_list = client.api('v1').resource('namespaces').list
      namespaces = []
      namespaces_list.each do |namespace|
        namespaces.push(namespace.metadata.name)
      end
      count = namespaces.select{|namespace| namespace == curent_username}
      if count.count == 0
        system("kubectl create namespace #{current_username}")
      end
      
      # check serviceaccount
      serviceaccount_user = client.api('v1').resource('serviceaccount', namespace: current_username).list
      serviceaccount_user_count = serviceaccount_user.metadata.name
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

  def create_serviceaccount(client)
    serviceaccount = K8s::Resource.new(
      apiVersion: v1,
      kind: ServiceAccount,
      metadata: {
        name: "#{current_user.username}",
        namespace: "#{current_user.username}" 
      }
    )
    client.api('v1').resource('serviceaccounts').create_resource(serviceaccount)
  end
end
