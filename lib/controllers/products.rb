# frozen_string_literal: true

require_relative '../http_error'
require_relative '../json_body'
require_relative '../json_response'
require_relative '../pagination'
require_relative '../middleware/authentication'
require_relative '../models/product'
require_relative '../services/request_product_creation'

module Controllers
  # Endpoints for the authenticated user's products.
  module Products
    MAX_NAME_LENGTH = 255

    module_function

    # GET /products: the user's products, oldest first, paginated by cursor.
    def index(request, _params)
      user_id = Middleware::Authentication.user_id(request)
      page = Pagination.paginate(Product.where(user_id:), request.GET)

      JsonResponse.build(200, { data: page.records.map(&:to_api), next_cursor: page.next_cursor })
    end

    # POST /products: asks for a product to be created DELAY_SECONDS later.
    # 202 while the creation is pending (poll the Location URL), 200 if the product already exists.
    # Repeating the same name never creates a second product.
    def create(request, _params)
      product_request = RequestProductCreation.call(
        user_id: Middleware::Authentication.user_id(request),
        name: name_from(JsonBody.parse(request))
      )
      respond_with(product_request)
    rescue RequestProductCreation::QueueUnavailable
      raise HttpError.new(503, 'queue_unavailable')
    end

    def name_from(body)
      name = body['name']
      name = name.strip if name.is_a?(String)
      return name if name.is_a?(String) && name.length.between?(1, MAX_NAME_LENGTH)

      raise HttpError.new(422, 'invalid_params',
                          details: { 'name' => "must be a non-empty string of at most #{MAX_NAME_LENGTH} characters" })
    end

    def respond_with(product_request)
      location = { 'location' => "/products/requests/#{product_request.id}" }
      return JsonResponse.build(200, product_request.to_api, location) unless product_request.pending?

      JsonResponse.build(202, product_request.to_api,
                         location.merge('retry-after' => RequestProductCreation::DELAY_SECONDS.to_s))
    end
  end
end
