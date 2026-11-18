# frozen_string_literal: true

RSpec.describe 'POST /products', type: :request do
  let(:user) { create_user }

  def create_product_request(body, headers = {})
    headers.each { |name, value| header name, value }
    post '/products', JSON.generate(body), 'CONTENT_TYPE' => 'application/json'
  end

  def json_body = JSON.parse(last_response.body)

  def product_names
    get '/products'
    JSON.parse(last_response.body)['data'].map { |product| product['name'] }
  end

  context 'without a token' do
    it 'returns 401' do
      create_product_request(name: 'Mate')

      expect(last_response.status).to eq(401)
    end
  end

  context 'with a valid name' do
    before do
      authenticate_as(user.id)
      create_product_request(name: 'Mate')
    end

    it 'accepts the request with 202 and a pending status', :aggregate_failures do
      expect(last_response.status).to eq(202)
      expect(json_body).to include('name' => 'Mate', 'status' => 'pending', 'product_id' => nil)
    end

    it 'points to the request status with Location and Retry-After', :aggregate_failures do
      expect(last_response.headers['location']).to eq("/products/requests/#{json_body['id']}")
      expect(last_response.headers['retry-after']).to eq('5')
    end

    it 'schedules the creation 5 seconds later' do
      expect(CreateProductJob.jobs.last['at']).to be_within(1).of(Time.now.to_f + 5)
    end

    it 'does not create the product right away' do
      expect(product_names).to be_empty
    end

    it 'makes the product available once the job runs', :aggregate_failures do
      request_id = json_body['id']
      CreateProductJob.drain

      expect(product_names).to eq(['Mate'])
      expect(ProductRequest[request_id].status).to eq('completed')
    end
  end

  context 'when the user already has a product with that name' do
    it 'returns 409 name_taken', :aggregate_failures do
      create_product(user:, name: 'Mate')
      authenticate_as(user.id)
      create_product_request(name: 'Mate')

      expect(last_response.status).to eq(409)
      expect(json_body).to eq('error' => 'name_taken')
    end
  end

  context 'when a creation with that name is already pending' do
    it 'returns 409 creation_already_pending', :aggregate_failures do
      authenticate_as(user.id)
      2.times { create_product_request(name: 'Mate') }

      expect(last_response.status).to eq(409)
      expect(json_body).to eq('error' => 'creation_already_pending')
    end
  end

  context 'when another user has a product with that name' do
    it 'accepts the request' do
      create_product(user: create_user, name: 'Mate')
      authenticate_as(user.id)
      create_product_request(name: 'Mate')

      expect(last_response.status).to eq(202)
    end
  end

  context 'when retried with the same Idempotency-Key' do
    before { authenticate_as(user.id) }

    it 'returns the original request without enqueuing a second job', :aggregate_failures do
      create_product_request({ name: 'Mate' }, 'Idempotency-Key' => 'key-1')
      first_response = json_body
      create_product_request({ name: 'Mate' }, 'Idempotency-Key' => 'key-1')

      expect(json_body).to eq(first_response)
      expect(CreateProductJob.jobs.size).to eq(1)
    end

    it 'rejects the key when reused for a different name', :aggregate_failures do
      create_product_request({ name: 'Mate' }, 'Idempotency-Key' => 'key-1')
      create_product_request({ name: 'Yerba' }, 'Idempotency-Key' => 'key-1')

      expect(last_response.status).to eq(422)
      expect(json_body).to eq('error' => 'idempotency_key_reused')
    end
  end

  context 'with an invalid name' do
    before { authenticate_as(user.id) }

    [nil, '', '   ', 123, 'x' * 256].each do |name|
      it "rejects #{name.inspect[0, 20]} with 422", :aggregate_failures do
        create_product_request(name:)

        expect(last_response.status).to eq(422)
        expect(json_body['details'].keys).to eq(['name'])
      end
    end
  end

  context 'with surrounding whitespace in the name' do
    it 'stores the trimmed name' do
      authenticate_as(user.id)
      create_product_request(name: '  Mate  ')

      expect(json_body['name']).to eq('Mate')
    end
  end

  context 'when the job queue is unavailable' do
    before do
      allow(CreateProductJob).to receive(:perform_in).and_raise(RedisClient::CannotConnectError)
      authenticate_as(user.id)
      create_product_request(name: 'Mate')
    end

    it 'returns 503 queue_unavailable' do
      expect(last_response.status).to eq(503)
    end

    it 'does not leave the request pending' do
      expect(ProductRequest.first(user_id: user.id).status).to eq('failed')
    end
  end
end
