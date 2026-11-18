# frozen_string_literal: true

require_relative '../http_error'
require_relative '../json_body'
require_relative '../json_response'
require_relative '../services/authenticate_user'
require_relative '../services/token_service'

module Controllers
  # POST /auth: exchanges a username and password for an access token.
  module Auth
    module_function

    def create(request, _params)
      body = JsonBody.parse(request)
      username, password = credentials_from(body)

      user = AuthenticateUser.call(username:, password:)
      token_response(TokenService.issue(user.id))
    rescue AuthenticateUser::InvalidCredentials
      raise HttpError.new(401, 'invalid_credentials')
    end

    def token_response(token)
      JsonResponse.build(
        200,
        { access_token: token, token_type: 'Bearer', expires_in: Settings.jwt_ttl_seconds },
        { 'cache-control' => 'no-store' }
      )
    end

    def credentials_from(body)
      errors = {}
      %w[username password].each do |field|
        errors[field] = 'must be a non-empty string' unless body[field].is_a?(String) && !body[field].empty?
      end
      raise HttpError.new(422, 'invalid_params', details: errors) if errors.any?

      [body['username'], body['password']]
    end
  end
end
