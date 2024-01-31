class ApplicationController < ActionController::Base
  http_basic_authenticate_with :name => ENV['API_USER'], :password => ENV['API_PASS']
end
