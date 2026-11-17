# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require_relative '../config/boot'
require_relative '../lib/app'
require 'rack/test'

Dir[File.join(__dir__, 'support/**/*.rb')].each { |file| require file }

RSpec.configure do |config|
  config.include EnvHelpers
  config.include Rack::Test::Methods, type: :request
  config.include RequestHelpers, type: :request

  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.order = :random
  Kernel.srand config.seed
  config.filter_run_when_matching :focus
end
