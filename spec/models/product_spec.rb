# frozen_string_literal: true

RSpec.describe Product do
  let(:user) { create_user }

  describe 'name uniqueness' do
    it 'rejects a second product with the same name for the same user' do
      create_product(user:, name: 'Mate')

      expect { create_product(user:, name: 'Mate') }.to raise_error(Sequel::UniqueConstraintViolation)
    end

    it 'allows the same name for different users' do
      create_product(user:, name: 'Mate')

      expect { create_product(user: create_user, name: 'Mate') }.not_to raise_error
    end
  end

  describe '#to_api' do
    it 'exposes id, name and an ISO 8601 UTC creation time' do
      product = create_product(user:, name: 'Mate')

      expect(product.to_api).to eq(id: product.id, name: 'Mate', created_at: product.created_at.utc.iso8601)
    end
  end
end
