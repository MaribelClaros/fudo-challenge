# frozen_string_literal: true

require 'time'

# A product owned by a user. Names are unique per user (enforced by a database index).
class Product < Sequel::Model
  many_to_one :user

  # The public JSON representation of a product.
  def to_api
    { id:, name:, created_at: created_at.utc.iso8601 }
  end
end
