# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:products) do
      primary_key :id, type: :Bignum
      foreign_key :user_id, :users, type: :Bignum, null: false, on_delete: :cascade
      String :name, null: false
      column :created_at, :timestamptz, null: false, default: Sequel::CURRENT_TIMESTAMP
      column :updated_at, :timestamptz, null: false, default: Sequel::CURRENT_TIMESTAMP

      # A user can't have two products with the same name.
      index %i[user_id name], unique: true
      # Serves the paginated listing: WHERE user_id = ? AND id > ? ORDER BY id.
      index %i[user_id id]
    end
  end
end
