require 'rails_helper'
require './spec/support/cache_helper'
include CacheHelper

RSpec.describe DevicesController, type: :controller do
  let(:id) { "id" }
  let(:device_id) { "device_#{id}" }
  let(:timestamps) { {} }
  let(:latest_timestamp) { Time.current.utc.to_s }
  let(:cumulative_count) { 5 }
  let(:readings_payload) do
    {
      timestamps: timestamps,
      latest_timestamp: latest_timestamp,
      cumulative_count: cumulative_count
    }
  end
  let(:auth_headers) do
    {
      'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(
        ENV['API_USER'],
        ENV['API_PASS']
      )
    }
  end

  before do
    request.headers.merge!(auth_headers)
  end

  around do |test|
    with_cache_cleanup do
      Rails.cache.write(device_id, readings_payload)
      test.run
    end
  end

  describe 'GET /devices/:id/latest_timestamp' do
    context 'when request is successful' do
      let(:expected_body) do
        { latest_timestamp: latest_timestamp }.with_indifferent_access
      end

      before do
        allow(Rails.cache).to receive(:fetch).and_return(readings_payload.with_indifferent_access)
      end

      it "returns success" do
        get :latest_timestamp, params: { id: id }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eql(expected_body)
      end
    end

    context 'when not authorized' do
      let(:auth_headers) { {} }

      it "returns unauthorized" do
        get :latest_timestamp, params: { id: id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when not found' do
      let(:bad_id) { "non existent" }

      it "returns not found" do
        get :latest_timestamp, params: { id: bad_id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /devices/:id/cumulative_count' do
    context 'when request is successful' do
      let(:expected_body) do
        { cumulative_count: cumulative_count }.with_indifferent_access
      end

      before do
        allow(Rails.cache).to receive(:fetch).and_return(readings_payload.with_indifferent_access)
      end

      it "returns success" do
        get :cumulative_count, params: { id: id }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eql(expected_body)
      end
    end

    context 'when not authorized' do
      let(:auth_headers) { {} }

      it "returns unauthorized" do
        get :cumulative_count, params: { id: id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when not found' do
      let(:bad_id) { "non existent" }

      it "returns not found" do
        get :cumulative_count, params: { id: bad_id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
