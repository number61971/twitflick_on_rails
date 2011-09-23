require 'net/http'
require 'uri'

class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def http_get(url)
      # convenience function to handle http requests
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host)
      req = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(req)
      response.body
  end

end
