# frozen_string_literal: true

require_relative '../http_error'
require_relative '../json_response'
require_relative '../pagination'
require_relative '../middleware/authentication'
require_relative '../models/product_request'

module Controllers
  # Lets clients follow an asynchronous product creation.
  module ProductRequests
    module_function

    # GET /products/requests/:id: the request's status. Another user's request is reported
    # as not found, so ids can't be used to learn about other users' activity.
    def show(request, params)
      id = Integer(params['id'], 10, exception: false)
      product_request = id&.between?(1, Pagination::MAX_ID) &&
                        ProductRequest.first(id:, user_id: Middleware::Authentication.user_id(request))
      raise HttpError.new(404, 'not_found') unless product_request

      JsonResponse.build(200, product_request.to_api)
    end
  end
end
