# frozen_string_literal: true

require 'zlib'

RSpec.describe 'Response compression', type: :request do
  # Compression doesn't depend on the database, so the health check is stubbed to always succeed.
  before { allow(DB).to receive(:test_connection).and_return(true) }

  context 'when the client accepts gzip' do
    it 'compresses the response body', :aggregate_failures do
      header 'Accept-Encoding', 'gzip'
      get '/health'

      expect(last_response.headers['content-encoding']).to eq('gzip')
      expect(Zlib.gunzip(last_response.body)).to eq('{"status":"ok"}')
    end
  end

  context 'when the client does not accept gzip' do
    it 'returns the body uncompressed', :aggregate_failures do
      get '/health'

      expect(last_response.headers['content-encoding']).to be_nil
      expect(last_response.body).to eq('{"status":"ok"}')
    end
  end

  it 'sets Vary: Accept-Encoding so caches store each version separately' do
    get '/health'

    expect(last_response.headers['vary']).to include('Accept-Encoding')
  end
end
