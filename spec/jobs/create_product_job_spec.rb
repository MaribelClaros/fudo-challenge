# frozen_string_literal: true

RSpec.describe CreateProductJob do
  let(:user) { create_user }
  let(:request) { ProductRequest.create(user_id: user.id, name: 'Mate') }

  def run_job = described_class.new.perform(request.id)

  context 'with a pending request' do
    it 'creates the product and completes the request', :aggregate_failures do
      run_job

      product = Product.first(user_id: user.id, name: 'Mate')
      expect(product).not_to be_nil
      expect(request.reload).to have_attributes(status: 'completed', product_id: product.id, error: nil)
    end
  end

  context 'when it runs twice for the same request' do
    it 'creates the product only once and keeps the request completed', :aggregate_failures do
      2.times { run_job }

      expect(Product.where(user_id: user.id, name: 'Mate').count).to eq(1)
      expect(request.reload.status).to eq('completed')
    end
  end

  context 'when the user already has a product with that name' do
    it 'fails the request with name_taken' do
      create_product(user:, name: 'Mate')
      run_job

      expect(request.reload).to have_attributes(status: 'failed', error: 'name_taken')
    end
  end

  context 'when the request no longer exists' do
    it 'does nothing' do
      expect { described_class.new.perform(0) }.not_to raise_error
    end
  end

  context 'when every retry has failed' do
    it 'marks the request as failed so it does not stay pending forever' do
      described_class.sidekiq_retries_exhausted_block.call({ 'args' => [request.id] }, StandardError.new)

      expect(request.reload).to have_attributes(status: 'failed', error: 'processing_failed')
    end
  end
end
