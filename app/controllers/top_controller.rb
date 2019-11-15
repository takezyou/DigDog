class TopController < ApplicationController
  def index
    current_username = current_user.username
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))

    resourcequota_list = client.api('v1').resource('resourcequotas', namespace: current_user.username).list
    @resourcequota = []
  end
end
