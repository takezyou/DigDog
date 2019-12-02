class TopController < ApplicationController
  before_action :authenticate_user!

  def index
    current_username = current_user.username
    client = K8s::Client.config(K8s::Config.load_file(File.join(Rails.root, "config", "k8s_config.yml")))

    resourcequota_list = client.api('v1').resource('resourcequotas', namespace: current_user.username).list
    pods_top_list = client.api('metrics.k8s.io/v1beta1').resource('pods', namespace: current_user.username).list
    hard = resourcequota_list[0].dig(:status, :hard).to_h
    used = resourcequota_list[0].dig(:status, :used).to_h
    @limits_memory = hard[:"limits.memory"]
    @limits_cpu = hard[:"limits.cpu"]
    @requests_memory = hard[:"requests.memory"]
    @requests_cpu = hard[:"requests.cpu"]
    @used_limits_memory = used[:"limits.memory"]
    @used_limits_cpu = used[:"limits.cpu"].delete("m").to_f / 1000
    @used_requests_memory = used[:"requests.memory"]
    @used_requests_cpu = used[:"requests.cpu"].delete("m").to_f / 1000

    limits_memory_float = used[:"limits.memory"].delete("Mi").to_f
    requests_memory_float = used[:"requests.memory"].delete("Mi").to_f
    @graph_limits_memory = (limits_memory_float / (@limits_memory.to_f * 1000)) * 100
    @graph_requests_memory = (requests_memory_float / (@requests_memory.to_f * 1000)) * 100
    @graph_limits_cpu = (@used_limits_cpu / @limits_cpu.to_f) * 100
    @graph_requests_cpu = (@used_requests_cpu / @requests_cpu.to_f) * 100

    usage_memory = 0
    usage_cpu = 0
    pods_top_list.each do |top|
      used = top.to_h
      puts used
      if used.dig(:containers, 0)
        content = used.dig(:containers, 0, :usage)
        memory = content.dig(:memory)
        byte = memory.slice!(/Ki|Mi/)
        if byte == "Ki"
          m = memory.to_f / 1024
          usage_memory += m
        elsif byte == "Mi"
          m = memory.to_f
          usage_memory += m
        end
        cpu = content.dig(:cpu)
        milli = cpu.slice!(/m/).to_f
        usage_cpu += milli
      end
    end
    @usage_memory = "#{usage_memory}Mi"
    @usage_cpu = "#{usage_cpu}m"
    @graph_usage_memory = (usage_memory / (@limits_memory.to_f * 1000)) * 100
    @graph_usage_cpu = (usage_cpu / @limits_cpu.to_f) * 100
  end
end
