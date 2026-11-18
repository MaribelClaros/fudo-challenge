# frozen_string_literal: true

require_relative '../lib/json_body'

RSpec.describe JsonBody do
  def request_with(body, content_type: 'application/json')
    env = Rack::MockRequest.env_for('/', method: 'POST', input: body, 'CONTENT_TYPE' => content_type)
    Rack::Request.new(env)
  end

  def http_error(status, code)
    an_instance_of(HttpError).and(having_attributes(status:, code:))
  end

  it 'returns the parsed JSON object' do
    expect(described_class.parse(request_with('{"username":"demo"}'))).to eq('username' => 'demo')
  end

  it 'accepts a charset in the content type' do
    request = request_with('{}', content_type: 'application/json; charset=utf-8')

    expect(described_class.parse(request)).to eq({})
  end

  it 'rejects other content types with 415' do
    expect { described_class.parse(request_with('{}', content_type: 'text/plain')) }
      .to raise_error(http_error(415, 'unsupported_media_type'))
  end

  it 'rejects malformed JSON with 400' do
    expect { described_class.parse(request_with('{"username":')) }.to raise_error(http_error(400, 'invalid_json'))
  end

  it 'rejects an empty body with 400' do
    expect { described_class.parse(request_with('')) }.to raise_error(http_error(400, 'invalid_json'))
  end

  it 'rejects JSON that is not an object with 400' do
    expect { described_class.parse(request_with('["demo"]')) }.to raise_error(http_error(400, 'invalid_json'))
  end

  it 'rejects bodies over the size limit with 413' do
    body = JSON.generate(data: 'x' * JsonBody::MAX_BYTES)

    expect { described_class.parse(request_with(body)) }.to raise_error(http_error(413, 'payload_too_large'))
  end
end
