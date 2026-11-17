# frozen_string_literal: true

RSpec.describe 'Routing', type: :request do
  context 'when the path does not exist' do
    it 'returns 404 not found', :aggregate_failures do
      get '/nope'

      expect(last_response.status).to eq(404)
      expect(JSON.parse(last_response.body)).to eq('error' => 'not_found')
    end
  end

  context 'when the path exists but not for the HTTP method used' do
    it 'returns 405 listing the allowed methods', :aggregate_failures do
      post '/health'

      expect(last_response.status).to eq(405)
      expect(last_response.headers['allow']).to eq('GET')
      expect(JSON.parse(last_response.body)).to eq('error' => 'method_not_allowed')
    end
  end
end
