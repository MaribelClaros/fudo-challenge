# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id, type: :Bignum
      String :username, null: false
      String :password_digest, null: false
      column :created_at, :timestamptz, null: false, default: Sequel::CURRENT_TIMESTAMP
      column :updated_at, :timestamptz, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :username, unique: true
    end
  end
end
