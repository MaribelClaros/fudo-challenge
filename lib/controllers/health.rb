# frozen_string_literal: true

require_relative '../json_response'

module Controllers
  # Liveness/readiness check used by load balancers and container orchestrators.
  module Health
    module_function

    def show(_request, _params)
      DB.test_connection
      JsonResponse.build(200, { status: 'ok' })
    rescue Sequel::Error
      JsonResponse.build(503, { status: 'unavailable' })
    end
  end
end
