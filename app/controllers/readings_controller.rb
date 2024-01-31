class ReadingsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    result = ReadingsCreator.new(device_params).create
    if result[:failed].empty?
      render json: device_params.as_json, status: :created
    else
      render json: {
        id: device_params[:id],
        successful: result[:successful],
        failed: result[:failed]
      }, status: :multi_status
    end
  end

  private

  def device_params
    params.require(:readings).permit(:id, :readings => [:timestamp, :count])
  end
end
