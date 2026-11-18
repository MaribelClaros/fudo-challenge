# frozen_string_literal: true

require 'sidekiq'
require_relative '../models/product'
require_relative '../models/product_request'

# Creates the product for a pending ProductRequest.
#
# Sidekiq delivers jobs at least once, so this may run more than once for the same request.
# It is idempotent: the request row is locked and only processed while still pending.
class CreateProductJob
  include Sidekiq::Job
  sidekiq_options retry: 5

  # After the last retry, don't leave the request pending forever.
  sidekiq_retries_exhausted do |job, _error|
    ProductRequest.where(id: job['args'].first, status: 'pending')
                  .update(status: 'failed', error: 'processing_failed', updated_at: Sequel::CURRENT_TIMESTAMP)
  end

  def perform(request_id)
    DB.transaction do
      request = ProductRequest.where(id: request_id).for_update.first
      next unless request&.pending?

      create_product(request)
    end
  end

  private

  def create_product(request)
    # The savepoint lets the outer transaction survive a unique violation and record the failure.
    product = DB.transaction(savepoint: true) { Product.create(user_id: request.user_id, name: request.name) }
    request.update(status: 'completed', product_id: product.id)
  rescue Sequel::UniqueConstraintViolation
    request.update(status: 'failed', error: 'name_taken')
  end
end
