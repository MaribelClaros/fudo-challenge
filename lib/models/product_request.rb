# frozen_string_literal: true

require 'time'

# A request to create a product asynchronously. Starts as pending; the worker marks it
# completed (pointing to the new product) or failed (with an error code).
class ProductRequest < Sequel::Model
  many_to_one :user
  many_to_one :product

  def pending? = status == 'pending'

  # The public JSON representation of the request.
  def to_api
    { id:, name:, status:, product_id:, error:, created_at: created_at.utc.iso8601 }
  end
end
