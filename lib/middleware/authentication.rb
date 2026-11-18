# frozen_string_literal: true

require_relative '../http_error'
require_relative '../services/token_service'

module Middleware
  # Requires a valid bearer token on every route except the public ones.
  # On success, exposes the authenticated user's id to the app as env['app.user_id'].
  #
  # Unknown paths are not public, so unauthenticated clients get 401 instead of 404:
  # they can't probe the API to discover which routes exist.
  class Authentication
    PUBLIC_PATHS = ['/health', '/auth', '/AUTHORS'].freeze
    USER_ID_KEY = 'app.user_id'

    # The authenticated user's id, for controllers behind this middleware.
    def self.user_id(request) = request.env[USER_ID_KEY]

    def initialize(app)
      @app = app
    end

    def call(env)
      env[USER_ID_KEY] = authenticate!(env) unless public_path?(env)
      @app.call(env)
    end

    private

    def public_path?(env) = PUBLIC_PATHS.include?(env['PATH_INFO'])

    def authenticate!(env)
      token = bearer_token(env)
      raise unauthorized('missing_token') unless token

      TokenService.verify(token)
    rescue TokenService::InvalidToken
      raise unauthorized('invalid_token')
    end

    def bearer_token(env)
      header = env['HTTP_AUTHORIZATION'].to_s
      header.delete_prefix('Bearer ') if header.start_with?('Bearer ')
    end

    def unauthorized(code) = HttpError.new(401, code, headers: { 'www-authenticate' => 'Bearer' })
  end
end
