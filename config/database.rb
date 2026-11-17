# frozen_string_literal: true

require 'sequel'

DB = Sequel.connect(Settings.database_url, max_connections: Settings.db_pool_size)
DB.test_connection

# Fills created_at/updated_at automatically on every model.
Sequel::Model.plugin :timestamps, update_on_create: true
