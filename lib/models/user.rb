# frozen_string_literal: true

require 'bcrypt'

# An API user. Only a bcrypt hash of the password is stored, never the password itself.
class User < Sequel::Model
  def password=(plain_password)
    self.password_digest = BCrypt::Password.create(plain_password).to_s
  end
end
