# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:products) do
      drop_index %i[user_id name]
      add_index [:user_id, Sequel.function(:lower, :name)], unique: true, name: :products_user_id_lower_name_index
    end

    alter_table(:product_requests) do
      drop_index %i[user_id name], name: :product_requests_one_pending_per_name
      add_index [:user_id, Sequel.function(:lower, :name)],
                unique: true, where: { status: 'pending' }, name: :product_requests_one_pending_per_name
      drop_index %i[user_id idempotency_key]
      drop_column :idempotency_key
    end
  end

  down do
    alter_table(:product_requests) do
      add_column :idempotency_key, String
      add_index %i[user_id idempotency_key], unique: true
      drop_index nil, name: :product_requests_one_pending_per_name
      add_index %i[user_id name],
                unique: true, where: { status: 'pending' }, name: :product_requests_one_pending_per_name
    end

    alter_table(:products) do
      drop_index nil, name: :products_user_id_lower_name_index
      add_index %i[user_id name], unique: true
    end
  end
end
