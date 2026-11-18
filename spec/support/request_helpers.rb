# frozen_string_literal: true

# Helpers for request specs (type: :request).
module RequestHelpers
  # The Rack app that Rack::Test sends requests to.
  def app = App.build

  # Sends a valid access token for the given user id on the following requests.
  def authenticate_as(user_id)
    header 'Authorization', "Bearer #{TokenService.issue(user_id)}"
  end
end
