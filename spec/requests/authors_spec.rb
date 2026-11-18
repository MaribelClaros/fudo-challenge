# frozen_string_literal: true

require 'zlib'

RSpec.describe 'GET /AUTHORS', type: :request do
  let(:file_contents) { File.read(Controllers::Authors::PATH) }

  it 'returns the AUTHORS file as plain text without a token', :aggregate_failures do
    get '/AUTHORS'

    expect(last_response.status).to eq(200)
    expect(last_response.headers['content-type']).to eq('text/plain; charset=utf-8')
    expect(last_response.body).to eq(file_contents)
  end

  it 'lets clients and proxies cache it for 24 hours' do
    get '/AUTHORS'

    expect(last_response.headers['cache-control']).to eq('public, max-age=86400')
  end

  context 'when revalidating with the ETag it got before' do
    it 'returns an empty 304 Not Modified', :aggregate_failures do
      get '/AUTHORS'
      header 'If-None-Match', last_response.headers['etag']
      get '/AUTHORS'

      expect(last_response.status).to eq(304)
      expect(last_response.body).to be_empty
    end
  end

  context 'when revalidating with an outdated ETag' do
    it 'returns the whole file again' do
      header 'If-None-Match', '"outdated"'
      get '/AUTHORS'

      expect(last_response.status).to eq(200)
    end
  end

  context 'when the client accepts gzip' do
    it 'compresses the file', :aggregate_failures do
      header 'Accept-Encoding', 'gzip'
      get '/AUTHORS'

      expect(last_response.headers['content-encoding']).to eq('gzip')
      expect(Zlib.gunzip(last_response.body)).to eq(file_contents)
    end
  end
end
