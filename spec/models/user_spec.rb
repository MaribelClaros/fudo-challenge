# frozen_string_literal: true

require_relative '../../lib/models/user'

RSpec.describe User do
  describe '#password=' do
    it 'stores a bcrypt hash instead of the plain password', :aggregate_failures do
      user = described_class.new(username: 'alice')
      user.password = 's3cret-password'

      expect(user.password_digest).not_to eq('s3cret-password')
      expect(BCrypt::Password.new(user.password_digest)).to eq('s3cret-password')
    end
  end
end
