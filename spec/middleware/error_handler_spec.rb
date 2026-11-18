# frozen_string_literal: true

require 'stringio'

RSpec.describe Middleware::ErrorHandler, type: :request do
  let(:errors) { StringIO.new }
  let(:app) { described_class.new(inner_app) }

  def json_body = JSON.parse(last_response.body)

  context 'when the request succeeds' do
    let(:inner_app) { ->(_env) { [200, {}, ['ok']] } }

    it 'passes the response through untouched' do
      get '/'

      expect(last_response.body).to eq('ok')
    end
  end

  context 'when an HttpError is raised' do
    let(:inner_app) do
      lambda do |_env|
        raise HttpError.new(401, 'invalid_token', details: { reason: 'expired' },
                                                  headers: { 'www-authenticate' => 'Bearer' })
      end
    end

    it 'responds with its status, error code, details and headers', :aggregate_failures do
      get '/'

      expect(last_response.status).to eq(401)
      expect(json_body).to eq('error' => 'invalid_token', 'details' => { 'reason' => 'expired' })
      expect(last_response.headers['www-authenticate']).to eq('Bearer')
    end
  end

  context 'when an unexpected error is raised' do
    let(:inner_app) { ->(_env) { raise 'database password is hunter2' } }

    it 'responds with a generic 500 that leaks no details', :aggregate_failures do
      get '/', {}, 'rack.errors' => errors

      expect(last_response.status).to eq(500)
      expect(json_body).to eq('error' => 'internal_server_error')
    end

    it 'logs the error for the operators' do
      get '/', {}, 'rack.errors' => errors

      expect(errors.string).to include('RuntimeError: database password is hunter2')
    end
  end
end
