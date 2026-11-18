# frozen_string_literal: true

RSpec.describe 'GET /products/requests/:id', type: :request do
  let(:user) { create_user }
  let(:product_request) { ProductRequest.create(user_id: user.id, name: 'Mate') }

  def json_body = JSON.parse(last_response.body)

  context 'with the user own request' do
    it 'returns its status', :aggregate_failures do
      authenticate_as(user.id)
      get "/products/requests/#{product_request.id}"

      expect(last_response.status).to eq(200)
      expect(json_body).to include('id' => product_request.id, 'name' => 'Mate', 'status' => 'pending')
    end

    it 'reports the product once the creation completes' do
      CreateProductJob.new.perform(product_request.id)
      authenticate_as(user.id)
      get "/products/requests/#{product_request.id}"

      expect(json_body).to include('status' => 'completed', 'product_id' => Product.first(name: 'Mate').id)
    end
  end

  context "with another user's request" do
    it 'returns 404, as if it did not exist' do
      authenticate_as(create_user.id)
      get "/products/requests/#{product_request.id}"

      expect(last_response.status).to eq(404)
    end
  end

  %w[999999 abc 0 99999999999999999999].each do |id|
    context "with id #{id}" do
      it 'returns 404' do
        authenticate_as(user.id)
        get "/products/requests/#{id}"

        expect(last_response.status).to eq(404)
      end
    end
  end
end
