# frozen_string_literal: true

RSpec.describe 'GET /health', type: :request do
  context 'when the database is available' do
    it 'returns 200 with status ok', :aggregate_failures do
      get '/health'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq('status' => 'ok')
    end
  end

  context 'when the database is unavailable' do
    it 'returns 503 with status unavailable', :aggregate_failures do
      allow(DB).to receive(:test_connection).and_raise(Sequel::DatabaseConnectionError)
      get '/health'

      expect(last_response.status).to eq(503)
      expect(JSON.parse(last_response.body)).to eq('status' => 'unavailable')
    end
  end
end
