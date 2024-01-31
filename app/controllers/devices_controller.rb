class DevicesController < ApplicationController
  before_action :set_device, only: [:latest_timestamp, :cumulative_count]

  def latest_timestamp
    render json: { latest_timestamp: @device['latest_timestamp'] }, status: :ok
  end

  def cumulative_count
    render json: { cumulative_count: @device['cumulative_count'] }, status: :ok
  end

  private

  def set_device
    @device = Rails.cache.fetch("device_#{params[:id]}")
    raise CacheRecordNotFoundError if @device.nil?
  end
end
