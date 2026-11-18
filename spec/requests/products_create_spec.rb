# frozen_string_literal: true

RSpec.describe 'POST /products', type: :request do
  let(:user) { create_user }

  def create_product_request(name)
    post '/products', JSON.generate(name:), 'CONTENT_TYPE' => 'application/json'
  end

  def json_body = JSON.parse(last_response.body)

  def product_names
    get '/products'
    JSON.parse(last_response.body)['data'].map { |product| product['name'] }
  end

  context 'without a token' do
    it 'returns 401' do
      create_product_request('Mate')

      expect(last_response.status).to eq(401)
    end
  end

  context 'with a new name' do
    before do
      authenticate_as(user.id)
      create_product_request('Mate')
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

  context 'when the same name is already pending' do
    let!(:first_id) do
      authenticate_as(user.id)
      create_product_request('Mate')
      json_body['id']
    end

    it 'returns the same pending request with 202', :aggregate_failures do
      create_product_request('Mate')

      expect(last_response.status).to eq(202)
      expect(json_body['id']).to eq(first_id)
    end

    it 'does not enqueue another job' do
      create_product_request('Mate')

      expect(CreateProductJob.jobs.size).to eq(1)
    end

    it 'treats names that differ only in case as the same request' do
      create_product_request('MATE')

      expect(json_body['id']).to eq(first_id)
    end
  end

  context 'when the product already exists' do
    before do
      authenticate_as(user.id)
      create_product_request('Mate')
      CreateProductJob.drain
    end

    it 'returns the completed request with 200 and enqueues nothing', :aggregate_failures do
      create_product_request('mate')

      expect(last_response.status).to eq(200)
      expect(json_body).to include('name' => 'Mate', 'status' => 'completed')
      expect(CreateProductJob.jobs).to be_empty
    end

    it 'never creates a second product, however many times it is asked' do
      3.times { create_product_request('Mate') }
      CreateProductJob.drain

      expect(product_names).to eq(['Mate'])
    end
  end

  context 'when the product was created without a request' do
    it 'returns a completed request pointing to it', :aggregate_failures do
      product = create_product(user:, name: 'Mate')
      authenticate_as(user.id)
      create_product_request('Mate')

      expect(last_response.status).to eq(200)
      expect(json_body).to include('status' => 'completed', 'product_id' => product.id)
    end
  end

  context 'when a previous request for that name failed' do
    it 'accepts a new request so the creation can be retried', :aggregate_failures do
      failed = ProductRequest.create(user_id: user.id, name: 'Mate', status: 'failed', error: 'queue_unavailable')
      authenticate_as(user.id)
      create_product_request('Mate')

      expect(last_response.status).to eq(202)
      expect(json_body['id']).not_to eq(failed.id)
    end
  end

  context 'when a concurrent request for the same name is inserted first' do
    let(:competitor) { ProductRequest.new(user_id: user.id, name: 'Mate') }

    # Simulates another POST winning the race: its request is saved right before ours.
    before do
      allow(ProductRequest).to receive(:create).and_wrap_original do |create, **attributes|
        competitor.save if competitor.new?
        create.call(**attributes)
      end
      authenticate_as(user.id)
    end

    it 'returns that request instead of failing', :aggregate_failures do
      create_product_request('Mate')

      expect(last_response.status).to eq(202)
      expect(json_body['id']).to eq(competitor.id)
    end
  end

  context 'when another user has a product with that name' do
    it 'accepts the request' do
      create_product(user: create_user, name: 'Mate')
      authenticate_as(user.id)
      create_product_request('Mate')

      expect(last_response.status).to eq(202)
    end
  end

  context 'with an invalid name' do
    before { authenticate_as(user.id) }

    [nil, '', '   ', 123, 'x' * 256].each do |name|
      it "rejects #{name.inspect[0, 20]} with 422", :aggregate_failures do
        create_product_request(name)

        expect(last_response.status).to eq(422)
        expect(json_body['details'].keys).to eq(['name'])
      end
    end
  end

  context 'with surrounding whitespace in the name' do
    it 'stores the trimmed name' do
      authenticate_as(user.id)
      create_product_request('  Mate  ')

      expect(json_body['name']).to eq('Mate')
    end
  end

  context 'when the job queue is unavailable' do
    before do
      allow(CreateProductJob).to receive(:perform_in).and_raise(RedisClient::CannotConnectError)
      authenticate_as(user.id)
      create_product_request('Mate')
    end

    it 'returns 503 queue_unavailable' do
      expect(last_response.status).to eq(503)
    end

    it 'does not leave the request pending' do
      expect(ProductRequest.first(user_id: user.id).status).to eq('failed')
    end
  end
end
