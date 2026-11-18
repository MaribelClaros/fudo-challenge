# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:product_requests) do
      primary_key :id, type: :Bignum
      foreign_key :user_id, :users, type: :Bignum, null: false, on_delete: :cascade
      foreign_key :product_id, :products, type: :Bignum, on_delete: :set_null
      String :name, null: false
      String :status, null: false, default: 'pending'
      String :error
      String :idempotency_key
      column :created_at, :timestamptz, null: false, default: Sequel::CURRENT_TIMESTAMP
      column :updated_at, :timestamptz, null: false, default: Sequel::CURRENT_TIMESTAMP

      constraint(:valid_status, status: %w[pending completed failed])
      # A retried request with the same Idempotency-Key must not create a second request.
      index %i[user_id idempotency_key], unique: true
      # At most one pending creation per product name and user.
      index %i[user_id name], unique: true, where: { status: 'pending' }, name: :product_requests_one_pending_per_name
    end
  end
end
