require 'base64'

class ConfigController < ApplicationController
  def index
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
    secret_list = client.api('v1').resource('secrets', namespace: "#{current_user.username}").list
    secrets = []
    secret_list.each do |secret|
      secrets.push({name: secret.metadata.name, token: secret.data.token})
    end
    secret = secrets.select{|secret| secret[:name].include?("#{current_user.username}")}
    @token = Base64.decode64(secret[0][:token])
  end
end
