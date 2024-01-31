require 'rails_helper'
require './spec/support/cache_helper'
include CacheHelper

RSpec.describe Reading, type: :model do
  let(:timestamp) { Time.current.to_s }
  let(:count) { 5 }
  subject { described_class.new(timestamp: timestamp, count: count) }

  context 'when created with required attributes' do
    it 'returns as valid if the device exists' do
      expect(subject.valid?).to equal(true)
    end
  end

  context 'when required attributes are not properly formatted' do
    context 'when timestamp is invalid' do
      let(:timestamp) { 'not a timestamp' }
      let(:errors) { ["is not a valid timestamp"] }

      it 'returns as invalid' do
        expect(subject.valid?).to equal(false)
        expect(subject.errors.messages[:timestamp]).to eq(errors)
      end
    end

    context 'when count is not valid' do
      let(:count) { -1 }
      let(:errors) { ["must be greater than or equal to 0"] }

      it 'returns as invalid' do
        expect(subject.valid?).to equal(false)
        expect(subject.errors.messages[:count]).to eq(errors)
      end
    end
  end

  describe '#add_reading' do
    let(:device_id) { 'test '}
    let(:device_key) { "device_#{device_id}" }

    around do |test|
      with_cache_cleanup do
        test.run
      end
    end

    context 'when device does not exist' do
      let(:latest_timestamp) { Time.zone.parse(timestamp).utc.to_s }
      let(:timestamps) do
        {
          "#{latest_timestamp}": count,
        }.with_indifferent_access
      end
      let(:cumulative_count) { count }

      it 'stores the reading properly' do
        described_class.new(timestamp: timestamp, count: count).add_reading(device_id)
        device_reading = Rails.cache.fetch(device_key)
        expect(device_reading['timestamps']).to eq(timestamps)
        expect(device_reading['latest_timestamp']).to eq(latest_timestamp)
        expect(device_reading['cumulative_count']).to eq(cumulative_count)
      end
    end

    context 'when device exists' do
      let(:timestamp2) { (Time.current + 1.day).to_s }
      let(:count2) { 2 }
      let(:timestamps) do
        {
          "#{ Time.zone.parse(timestamp).utc.to_s}": count,
          "#{ Time.zone.parse(timestamp2).utc.to_s}": count2,
        }.with_indifferent_access
      end
      let(:latest_timestamp) { Time.zone.parse(timestamp2).utc.to_s }
      let(:cumulative_count) { count + count2 }

      it 'stores the reading properly' do
        described_class.new(timestamp: timestamp, count: count).add_reading(device_id)
        described_class.new(timestamp: timestamp2, count: count2).add_reading(device_id)
        device_reading = Rails.cache.fetch(device_key)
        expect(device_reading['timestamps']).to eq(timestamps)
        expect(device_reading['latest_timestamp']).to eq(latest_timestamp)
        expect(device_reading['cumulative_count']).to eq(cumulative_count)
      end
    end

    context 'when there are duplicates' do
      it 'ignores the reading' do
        described_class.new(timestamp: timestamp, count: count).add_reading(device_id)
        described_class.new(timestamp: timestamp, count: count).add_reading(device_id)
        device_reading = Rails.cache.fetch(device_key)
        expect(device_reading['timestamps'].length).to eq(1)
        expect(device_reading['cumulative_count']).to eq(count)
      end
    end
  end
end
