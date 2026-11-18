# frozen_string_literal: true

require 'securerandom'

# Minimal helpers to create records in specs. Names are random so examples never collide.
module Factories
  def create_user(username: "user-#{SecureRandom.hex(4)}", password: 'password')
    User.new(username:).tap { |user| user.password = password }.save
  end

  def create_product(user:, name: "product-#{SecureRandom.hex(4)}")
    Product.create(user_id: user.id, name:)
  end
end
