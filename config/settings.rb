# frozen_string_literal: true

# Centralized access to configuration coming from environment variables.
# Fails fast at boot if a required variable is missing or invalid.
module Settings
  class MissingConfigError < StandardError; end
  class InvalidConfigError < StandardError; end

  MIN_JWT_SECRET_LENGTH = 32

  module_function

  def env = ENV.fetch('RACK_ENV', 'development')
  def test? = env == 'test'

  def database_url = fetch!(database_url_key)
  def db_pool_size = Integer(ENV.fetch('DB_POOL', '5'))

  def jwt_secret = fetch!('JWT_SECRET')
  def jwt_ttl_seconds = Integer(ENV.fetch('JWT_TTL_SECONDS', '3600'))

  def validate!
    missing = required_keys.select { |key| ENV[key].to_s.strip.empty? }
    raise MissingConfigError, "Missing required environment variables: #{missing.join(', ')}" if missing.any?
    return if jwt_secret.length >= MIN_JWT_SECRET_LENGTH

    raise InvalidConfigError, "JWT_SECRET must be at least #{MIN_JWT_SECRET_LENGTH} characters long"
  end

  # The test suite uses its own database so it never touches development data.
  def database_url_key = test? ? 'TEST_DATABASE_URL' : 'DATABASE_URL'
  def required_keys = [database_url_key, 'JWT_SECRET']

  def fetch!(key)
    ENV.fetch(key) { raise MissingConfigError, "Missing required environment variable: #{key}" }
  end
end
