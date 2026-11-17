# frozen_string_literal: true

# Centralized access to configuration coming from environment variables.
# Fails fast at boot if a required variable is missing.
module Settings
  class MissingConfigError < StandardError; end

  module_function

  def env = ENV.fetch('RACK_ENV', 'development')
  def test? = env == 'test'

  def database_url = fetch!(database_url_key)
  def db_pool_size = Integer(ENV.fetch('DB_POOL', '5'))

  def validate!
    missing = required_keys.select { |key| ENV[key].to_s.strip.empty? }
    return if missing.empty?

    raise MissingConfigError, "Missing required environment variables: #{missing.join(', ')}"
  end

  # The test suite uses its own database so it never touches development data.
  def database_url_key = test? ? 'TEST_DATABASE_URL' : 'DATABASE_URL'
  def required_keys = [database_url_key]

  def fetch!(key)
    ENV.fetch(key) { raise MissingConfigError, "Missing required environment variable: #{key}" }
  end
end
