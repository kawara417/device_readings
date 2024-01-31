require 'rails_helper'
require './spec/support/cache_helper'
include CacheHelper

RSpec.describe ReadingsCreator do
  let(:id) { "36d5658a-6908-479e-887e-a949ec199272" }
  let(:device_key) { "device_#{id}" }
  let(:timestamp1) { "2021-09-29T16:08:15+01:00" }
  let(:timestamp2) { "2021-09-29T16:09:15+01:00" }
  let(:count1) { 2 }
  let(:count2) { 15 }
  let(:readings) do
    [
      { "timestamp": timestamp1, "count": count1 },
      { "timestamp": timestamp2, "count": count2 }
    ]
  end
  let(:params) do
    {
      "id": id,
      "readings": readings
    }
  end
  let(:cumulative_count) { count1 + count2 }
  let(:latest_timestamp) { Time.zone.parse(timestamp2).utc.to_s }

  describe '#create' do
    around do |test|
      with_cache_cleanup do
        test.run
      end
    end

    it 'creates readings' do
      described_class.new(params).create
      device_reading = Rails.cache.fetch(device_key)
      expect(device_reading['timestamps'].length).to eq(2)
      expect(device_reading['latest_timestamp']).to eq(latest_timestamp)
      expect(device_reading['cumulative_count']).to eq(cumulative_count)
    end

    it 'adds readings to successful results' do
      result = described_class.new(params).create
      expect(result[:successful].length).to eq(2)
    end

    context 'when there are readings with errors' do
      let(:count2) { -5 }
      let(:errors) { ["must be greater than or equal to 0"] }

      it 'adds readings to failed results' do
        result = described_class.new(params).create
        expect(result[:failed].length).to eq(1)
        expect(result[:failed].first[:errors][:count]).to eq(errors)
      end
    end
  end
end
