# frozen_string_literal: true

RSpec.describe 'POST /auth', type: :request do
  let!(:user) do
    User.new(username: 'alice').tap { |new_user| new_user.password = 'correct-password' }.save
  end

  def post_json(body)
    post '/auth', body.is_a?(String) ? body : JSON.generate(body), 'CONTENT_TYPE' => 'application/json'
  end

  def json_body = JSON.parse(last_response.body)

  context 'with valid credentials' do
    before { post_json(username: 'alice', password: 'correct-password') }

    it 'returns 200 with a bearer token that identifies the user', :aggregate_failures do
      expect(last_response.status).to eq(200)
      expect(json_body).to include('token_type' => 'Bearer', 'expires_in' => Settings.jwt_ttl_seconds)
      expect(TokenService.verify(json_body['access_token'])).to eq(user.id)
    end

    it 'forbids caching the token' do
      expect(last_response.headers['cache-control']).to eq('no-store')
    end
  end

  context 'with a wrong password' do
    it 'returns 401 invalid_credentials', :aggregate_failures do
      post_json(username: 'alice', password: 'wrong-password')

      expect(last_response.status).to eq(401)
      expect(json_body).to eq('error' => 'invalid_credentials')
    end
  end

  context 'with a username that does not exist' do
    it 'returns the same 401 as a wrong password, so it does not reveal which users exist' do
      post_json(username: 'nobody', password: 'wrong-password')
      unknown_user_response = [last_response.status, last_response.body]

      post_json(username: 'alice', password: 'wrong-password')

      expect(unknown_user_response).to eq([last_response.status, last_response.body])
    end
  end

  context 'with missing fields' do
    let(:details) { { 'username' => 'must be a non-empty string', 'password' => 'must be a non-empty string' } }

    it 'returns 422 listing every invalid field', :aggregate_failures do
      post_json({})

      expect(last_response.status).to eq(422)
      expect(json_body).to eq('error' => 'invalid_params', 'details' => details)
    end
  end

  context 'with a field of the wrong type' do
    it 'returns 422 for that field only', :aggregate_failures do
      post_json(username: 123, password: 'correct-password')

      expect(last_response.status).to eq(422)
      expect(json_body['details'].keys).to eq(['username'])
    end
  end

  context 'with an empty field' do
    it 'returns 422 for that field only', :aggregate_failures do
      post_json(username: 'alice', password: '')

      expect(last_response.status).to eq(422)
      expect(json_body['details'].keys).to eq(['password'])
    end
  end

  context 'with malformed JSON' do
    it 'returns 400 invalid_json', :aggregate_failures do
      post_json('{"username":')

      expect(last_response.status).to eq(400)
      expect(json_body).to eq('error' => 'invalid_json')
    end
  end

  context 'without a JSON content type' do
    it 'returns 415 unsupported_media_type' do
      post '/auth', 'username=alice&password=correct-password', 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

      expect(last_response.status).to eq(415)
    end
  end
end
