# frozen_string_literal: true

require 'bcrypt'
require_relative '../models/user'

# Checks a username/password pair. Takes the same time whether or not the user exists,
# so response times don't reveal which usernames are registered.
module AuthenticateUser
  class InvalidCredentials < StandardError; end

  # Compared against when the user doesn't exist, so bcrypt runs (and takes as long) either way.
  DUMMY_DIGEST = BCrypt::Password.create('dummy-password-for-timing').to_s

  module_function

  def call(username:, password:)
    user = User.first(username:)
    digest = user ? user.password_digest : DUMMY_DIGEST
    password_ok = BCrypt::Password.new(digest) == password
    raise InvalidCredentials unless password_ok && user

    user
  end
end
