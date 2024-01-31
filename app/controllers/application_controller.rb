class ApplicationController < ActionController::Base
  http_basic_authenticate_with :name => ENV['API_USER'], :password => ENV['API_PASS']

  rescue_from CacheRecordNotFoundError, with: :record_not_found

  private

  def record_not_found
    render :json => { message: 'Not Found' }, status: :not_found
  end
end
