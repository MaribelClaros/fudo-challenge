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
    MAX_IDEMPOTENCY_KEY_LENGTH = 255

    # How each failure of RequestProductCreation is reported to the client.
    CREATION_ERRORS = {
      RequestProductCreation::NameTaken => [409, 'name_taken'],
      RequestProductCreation::AlreadyPending => [409, 'creation_already_pending'],
      RequestProductCreation::IdempotencyKeyReused => [422, 'idempotency_key_reused'],
      RequestProductCreation::QueueUnavailable => [503, 'queue_unavailable']
    }.freeze

    module_function

    # GET /products: the user's products, oldest first, paginated by cursor.
    def index(request, _params)
      user_id = Middleware::Authentication.user_id(request)
      page = Pagination.paginate(Product.where(user_id:), request.GET)

      JsonResponse.build(200, { data: page.records.map(&:to_api), next_cursor: page.next_cursor })
    end

    # POST /products: accepts a creation request. The product becomes available
    # DELAY_SECONDS later; poll the URL in the Location header to follow it.
    def create(request, _params)
      product_request = RequestProductCreation.call(
        user_id: Middleware::Authentication.user_id(request),
        name: name_from(JsonBody.parse(request)),
        idempotency_key: idempotency_key_from(request)
      )
      accepted(product_request)
    rescue *CREATION_ERRORS.keys => e
      raise HttpError.new(*CREATION_ERRORS.fetch(e.class))
    end

    def name_from(body)
      name = body['name']
      name = name.strip if name.is_a?(String)
      return name if name.is_a?(String) && name.length.between?(1, MAX_NAME_LENGTH)

      raise HttpError.new(422, 'invalid_params',
                          details: { 'name' => "must be a non-empty string of at most #{MAX_NAME_LENGTH} characters" })
    end

    def idempotency_key_from(request)
      key = request.get_header('HTTP_IDEMPOTENCY_KEY')
      return key if key.nil? || key.length.between?(1, MAX_IDEMPOTENCY_KEY_LENGTH)

      raise HttpError.new(422, 'invalid_params',
                          details: { 'idempotency_key' => "must be 1 to #{MAX_IDEMPOTENCY_KEY_LENGTH} characters" })
    end

    def accepted(product_request)
      JsonResponse.build(
        202,
        product_request.to_api,
        { 'location' => "/products/requests/#{product_request.id}",
          'retry-after' => RequestProductCreation::DELAY_SECONDS.to_s }
      )
    end
  end
end
