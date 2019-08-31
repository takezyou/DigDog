require 'net/http'
require 'uri'
require 'json'

class CreateController < ApplicationController
  def new
    uri = URI.parse('https://registry.ie.u-ryukyu.ac.jp/v2/_catalog')
    json = Net::HTTP.get(uri)
    result = JSON.parse(json)
    @repo = result['repositories']
  end

  def state
    image = params[:image]
    name = params[:name]
    port = params[:port]

  end

end
