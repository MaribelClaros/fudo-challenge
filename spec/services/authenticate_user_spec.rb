# frozen_string_literal: true

require_relative '../../lib/services/authenticate_user'

RSpec.describe AuthenticateUser do
  let!(:user) do
    User.new(username: 'alice').tap { |new_user| new_user.password = 'correct-password' }.save
  end

  def authenticate(username, password) = described_class.call(username:, password:)

  context 'with the right username and password' do
    it 'returns the user' do
      expect(authenticate('alice', 'correct-password').id).to eq(user.id)
    end
  end

  context 'with a wrong password' do
    it 'raises InvalidCredentials' do
      expect { authenticate('alice', 'wrong-password') }.to raise_error(AuthenticateUser::InvalidCredentials)
    end
  end

  context 'with a username that does not exist' do
    it 'raises InvalidCredentials' do
      expect { authenticate('nobody', 'correct-password') }.to raise_error(AuthenticateUser::InvalidCredentials)
    end

    it 'still runs the bcrypt comparison, so it takes as long as a wrong password', :aggregate_failures do
      allow(BCrypt::Password).to receive(:new).and_call_original

      expect { authenticate('nobody', 'correct-password') }.to raise_error(AuthenticateUser::InvalidCredentials)
      expect(BCrypt::Password).to have_received(:new).with(AuthenticateUser::DUMMY_DIGEST)
    end

    it 'cannot be bypassed with the dummy password' do
      expect { authenticate('nobody', 'dummy-password-for-timing') }
        .to raise_error(AuthenticateUser::InvalidCredentials)
    end
  end

  context 'with the username in a different case' do
    it 'raises InvalidCredentials, because usernames are case-sensitive' do
      expect { authenticate('ALICE', 'correct-password') }.to raise_error(AuthenticateUser::InvalidCredentials)
    end
  end
end
