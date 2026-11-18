# frozen_string_literal: true

RSpec.describe Middleware::Authentication, type: :request do
  # The middleware wrapped by the ErrorHandler, as in the real app, around an inner app
  # that echoes the user id it receives.
  let(:inner_app) { ->(env) { [200, {}, [env['app.user_id'].inspect]] } }
  let(:app) { Middleware::ErrorHandler.new(described_class.new(inner_app)) }

  def json_body = JSON.parse(last_response.body)

  context 'with a public path' do
    it 'lets the request through without a token', :aggregate_failures do
      get '/health'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('nil')
    end
  end

  context 'with a valid token' do
    it 'passes the authenticated user id to the app', :aggregate_failures do
      header 'Authorization', "Bearer #{TokenService.issue(42)}"
      get '/products'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('42')
    end
  end

  context 'without an Authorization header' do
    it 'returns 401 missing_token asking for a bearer token', :aggregate_failures do
      get '/products'

      expect(last_response.status).to eq(401)
      expect(json_body).to eq('error' => 'missing_token')
      expect(last_response.headers['www-authenticate']).to eq('Bearer')
    end
  end

  context 'with a non-bearer Authorization header' do
    it 'returns 401 missing_token' do
      header 'Authorization', 'Basic ZGVtbzpkZW1v'
      get '/products'

      expect(json_body).to eq('error' => 'missing_token')
    end
  end

  context 'with an invalid token' do
    it 'returns 401 invalid_token', :aggregate_failures do
      header 'Authorization', 'Bearer not-a-token'
      get '/products'

      expect(last_response.status).to eq(401)
      expect(json_body).to eq('error' => 'invalid_token')
    end
  end

  context 'with an expired token' do
    it 'returns 401 invalid_token' do
      expired = TokenService.issue(42, now: Time.now - (Settings.jwt_ttl_seconds + 60))
      header 'Authorization', "Bearer #{expired}"
      get '/products'

      expect(json_body).to eq('error' => 'invalid_token')
    end
  end
end
