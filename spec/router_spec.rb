# frozen_string_literal: true

RSpec.describe Router, type: :request do
  # Overrides the default `app` (the whole application) with a router built just for this spec,
  # so path params can be tested before the real app has routes that use them.
  let(:app) do
    described_class.new do
      get '/items/:id', to: ->(_request, params) { [200, {}, [params['id']]] }
    end
  end

  describe 'named path params' do
    it 'passes them to the handler' do
      get '/items/42'

      expect(last_response.body).to eq('42')
    end

    it 'requires the whole path to match' do
      get '/items/42/extra'

      expect(last_response.status).to eq(404)
    end
  end
end
