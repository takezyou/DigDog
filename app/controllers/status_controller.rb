class StatusController < ApplicationController
  before_action :authenticate_user!

  def show
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))
    @pods = client.api('v1').resource('pods', namespace: 'kube-system').list
  end
end
