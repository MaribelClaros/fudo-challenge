# frozen_string_literal: true

# Gives request specs (type: :request) the Rack app that Rack::Test sends requests to.
module RequestHelpers
  def app = App.build
end
