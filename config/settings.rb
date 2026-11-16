# frozen_string_literal: true

# Centralized access to configuration coming from environment variables.
# Fails fast at boot if a required variable is missing.
module Settings
  class MissingConfigError < StandardError; end

  REQUIRED_KEYS = %w[DATABASE_URL].freeze

  module_function

  def env = ENV.fetch("RACK_ENV", "development")
  def database_url = fetch!("DATABASE_URL")
  def db_pool_size = Integer(ENV.fetch("DB_POOL", "5"))

  def validate!
    missing = REQUIRED_KEYS.select { |key| ENV[key].to_s.strip.empty? }
    return if missing.empty?

    raise MissingConfigError, "Missing required environment variables: #{missing.join(', ')}"
  end

  def fetch!(key)
    ENV.fetch(key) { raise MissingConfigError, "Missing required environment variable: #{key}" }
  end
end
