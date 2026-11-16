# frozen_string_literal: true

require "sequel"

DB = Sequel.connect(Settings.database_url, max_connections: Settings.db_pool_size)
DB.test_connection
