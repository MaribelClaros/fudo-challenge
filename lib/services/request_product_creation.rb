# frozen_string_literal: true

require 'redis_client'
require_relative '../models/product'
require_relative '../models/product_request'
require_relative '../jobs/create_product_job'

# Records a request to create a product and schedules the job that creates it
# DELAY_SECONDS later. The product does not exist when this returns.
module RequestProductCreation
  DELAY_SECONDS = 5

  class NameTaken < StandardError; end
  class AlreadyPending < StandardError; end
  class IdempotencyKeyReused < StandardError; end
  class QueueUnavailable < StandardError; end

  module_function

  # Returns the ProductRequest. With an Idempotency-Key that was already used,
  # returns the original request instead of creating a new one.
  def call(user_id:, name:, idempotency_key: nil)
    existing = idempotency_key && ProductRequest.first(user_id:, idempotency_key:)
    return replay(existing, name) if existing
    raise NameTaken unless Product.where(user_id:, name:).empty?

    request = insert_request(user_id, name, idempotency_key)
    enqueue(request)
    request
  end

  def replay(existing, name)
    raise IdempotencyKeyReused unless existing.name == name

    existing
  end

  def insert_request(user_id, name, idempotency_key)
    ProductRequest.create(user_id:, name:, idempotency_key:)
  rescue Sequel::UniqueConstraintViolation
    # Another request for this name (or with this key) was just created and is still pending.
    raise AlreadyPending
  end

  # Enqueued after the request is committed, so the job always finds it. If Redis is down
  # the request is marked failed instead of staying pending forever.
  def enqueue(request)
    CreateProductJob.perform_in(DELAY_SECONDS, request.id)
  rescue RedisClient::Error
    request.update(status: 'failed', error: 'queue_unavailable')
    raise QueueUnavailable
  end
end
