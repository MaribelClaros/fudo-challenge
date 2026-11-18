# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require_relative '../config/boot'

Sequel.extension :migration
begin
  Sequel::Migrator.check_current(DB, File.expand_path('../db/migrations', __dir__))
rescue Sequel::Migrator::NotCurrentError
  abort 'The test database has pending migrations. Run: RACK_ENV=test bundle exec rake db:migrate'
end

require_relative '../lib/app'
require 'bcrypt'
require 'rack/test'

# The minimum bcrypt cost keeps password hashing fast in tests; production uses the default (12).
BCrypt::Engine.cost = BCrypt::Engine::MIN_COST

Dir[File.join(__dir__, 'support/**/*.rb')].each { |file| require file }

RSpec.configure do |config|
  config.include EnvHelpers
  config.include Rack::Test::Methods, type: :request
  config.include RequestHelpers, type: :request

  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }

  # Every example runs inside a transaction that is rolled back at the end,
  # so tests never see each other's data.
  config.around do |example|
    DB.transaction(rollback: :always, auto_savepoint: true) { example.run }
  end

  config.order = :random
  Kernel.srand config.seed
  config.filter_run_when_matching :focus
end
