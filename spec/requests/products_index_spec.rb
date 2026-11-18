# frozen_string_literal: true

RSpec.describe 'GET /products', type: :request do
  let(:alice) { create_user(username: 'alice') }
  let(:bob) { create_user(username: 'bob') }

  def json_body = JSON.parse(last_response.body)
  def names = json_body['data'].map { |product| product['name'] }

  context 'without a token' do
    it 'returns 401' do
      get '/products'

      expect(last_response.status).to eq(401)
    end
  end

  context 'when the user has no products' do
    it 'returns an empty list', :aggregate_failures do
      authenticate_as(alice.id)
      get '/products'

      expect(last_response.status).to eq(200)
      expect(json_body).to eq('data' => [], 'next_cursor' => nil)
    end
  end

  context 'when several users have products' do
    before do
      create_product(user: alice, name: 'Mate')
      create_product(user: bob, name: 'Bombilla')
      create_product(user: alice, name: 'Yerba')
    end

    it "returns only the authenticated user's products, oldest first" do
      authenticate_as(alice.id)
      get '/products'

      expect(names).to eq(%w[Mate Yerba])
    end

    it 'never shows them to another user' do
      authenticate_as(bob.id)
      get '/products'

      expect(names).to eq(%w[Bombilla])
    end
  end

  describe 'product representation' do
    it 'includes id, name and creation time' do
      product = create_product(user: alice, name: 'Mate')
      authenticate_as(alice.id)
      get '/products'

      expect(json_body['data']).to eq([{ 'id' => product.id, 'name' => 'Mate',
                                         'created_at' => product.created_at.utc.iso8601 }])
    end
  end

  describe 'pagination' do
    before do
      25.times { |i| create_product(user: alice, name: format('product-%02d', i)) }
      authenticate_as(alice.id)
    end

    it 'returns 20 products by default with a cursor to the next page', :aggregate_failures do
      get '/products'

      expect(json_body['data'].size).to eq(20)
      expect(json_body['next_cursor']).to eq(json_body['data'].last['id'].to_s)
    end

    it 'returns the rest when following the cursor, with no further cursor', :aggregate_failures do
      get '/products'
      get '/products', after: json_body['next_cursor']

      expect(names).to eq((20..24).map { |i| format('product-%02d', i) })
      expect(json_body['next_cursor']).to be_nil
    end

    it 'honors a custom limit' do
      get '/products', limit: '5'

      expect(names).to eq((0..4).map { |i| format('product-%02d', i) })
    end

    it 'returns no cursor when the page is exactly the last one' do
      get '/products', limit: '25'

      expect(json_body['next_cursor']).to be_nil
    end
  end

  describe 'invalid pagination params' do
    before { authenticate_as(alice.id) }

    %w[0 101 abc -1].each do |limit|
      it "rejects limit=#{limit} with 422", :aggregate_failures do
        get '/products', limit: limit

        expect(last_response.status).to eq(422)
        expect(json_body['details'].keys).to eq(['limit'])
      end
    end

    %w[0 abc 99999999999999999999].each do |after|
      it "rejects after=#{after} with 422", :aggregate_failures do
        get '/products', after: after

        expect(last_response.status).to eq(422)
        expect(json_body['details'].keys).to eq(['after'])
      end
    end

    it 'reports every invalid param at once' do
      get '/products', limit: '0', after: 'abc'

      expect(json_body['details'].keys).to contain_exactly('limit', 'after')
    end
  end
end
