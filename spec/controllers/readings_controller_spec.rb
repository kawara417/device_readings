require 'rails_helper'

RSpec.describe ReadingsController, type: :controller do
  let(:id) { "36d5658a-6908-479e-887e-a949ec199272" }
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
      "readings": {
        "id": id,
        "readings": readings
      }
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

  describe 'POST /readings' do
    let(:readings_creator) { double('readings_creator') }

    context 'when request is successful' do
      let(:readings_creator_result) do
        {
          successful: successful,
          failed: failed
        }
      end

      before do
        allow(ReadingsCreator).to receive(:new).and_return(readings_creator)
        allow(readings_creator).to receive(:create).and_return(readings_creator_result)
      end

      context 'when there are no errors from readings creator' do
        let(:successful) { [] }
        let(:failed) { [] }
        let(:expected_readings) do
          [
            { "timestamp": timestamp1, "count": count1.to_s },
            { "timestamp": timestamp2, "count": count2.to_s }
          ]
        end
        let(:expected_body) do
          {
            id: id,
            readings: expected_readings
          }.with_indifferent_access
        end

        it "returns success" do
          post :create, params: params
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)).to eql(expected_body)
        end
      end

      context 'when there are errors from readings creator' do
        let(:successful) { [] }
        let(:failed) { ['some error'] }
        let(:expected_body) do
          {
            id: id,
            successful: successful,
            failed: failed
          }.with_indifferent_access
        end

        it "returns multi status" do
          post :create, params: params
          expect(response).to have_http_status(:multi_status)
          expect(JSON.parse(response.body)).to eql(expected_body)
        end
      end
    end

    context 'when not authorized' do
      let(:auth_headers) { {} }

      it "returns unauthorized" do
        post :create, params: params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
