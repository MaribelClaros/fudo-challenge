# frozen_string_literal: true

require 'redis_client'
require_relative '../models/product'
require_relative '../models/product_request'
require_relative '../jobs/create_product_job'

# Asks for a product to be created DELAY_SECONDS later and returns the ProductRequest that
# tracks it.
#
# Idempotent by (user, name), compared case-insensitively: a user can't have two products with
# the same name, so asking for the same name again is the same request. It returns:
# - the pending request, if that creation is already under way;
# - the completed request, if the product already exists;
# - otherwise (including after a failed attempt) a new pending request.
module RequestProductCreation
  DELAY_SECONDS = 5

  class QueueUnavailable < StandardError; end

  module_function

  def call(user_id:, name:)
    existing_request(user_id, name) || new_request(user_id, name)
  end

  def existing_request(user_id, name)
    pending_request(user_id, name) || completed_request(user_id, name)
  end

  def pending_request(user_id, name)
    ProductRequest.where(user_id:, status: 'pending').where(same_name(name)).first
  end

  # The request that created the product. A product inserted some other way gets one recorded.
  def completed_request(user_id, name)
    product = Product.where(user_id:).where(same_name(name)).first
    return unless product

    ProductRequest.where(product_id: product.id).order(:id).first ||
      ProductRequest.create(user_id:, name: product.name, status: 'completed', product_id: product.id)
  end

  def new_request(user_id, name)
    request = ProductRequest.create(user_id:, name:)
    enqueue(request)
    request
  rescue Sequel::UniqueConstraintViolation
    # A concurrent request for the same name was inserted first: that one is the request.
    existing_request(user_id, name) || raise
  end

  # Enqueued after the request is committed, so the job always finds it. If Redis is down
  # the request is marked failed instead of staying pending forever.
  def enqueue(request)
    CreateProductJob.perform_in(DELAY_SECONDS, request.id)
  rescue RedisClient::Error
    request.update(status: 'failed', error: 'queue_unavailable')
    raise QueueUnavailable
  end

  # lower(name) = lower(?): case-insensitive, and served by the indexes on lower(name).
  def same_name(name) = { Sequel.function(:lower, :name) => Sequel.function(:lower, name) }
end
