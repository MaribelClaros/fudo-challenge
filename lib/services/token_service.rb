# frozen_string_literal: true

require 'jwt'

# Issues and verifies the JWTs that authenticate API requests.
module TokenService
  ALGORITHM = 'HS256'

  class InvalidToken < StandardError; end

  module_function

  def issue(user_id, now: Time.now)
    issued_at = now.to_i
    payload = { sub: user_id.to_s, iat: issued_at, exp: issued_at + Settings.jwt_ttl_seconds }
    JWT.encode(payload, Settings.jwt_secret, ALGORITHM)
  end

  def verify(token)
    payload, _header = JWT.decode(token, Settings.jwt_secret, true, algorithm: ALGORITHM, required_claims: %w[sub exp])
    Integer(payload['sub'])
  rescue JWT::DecodeError
    raise InvalidToken
  end
end
