# frozen_string_literal: true

require 'securerandom'
require_relative '../../lib/services/token_service'

RSpec.describe TokenService do
  def build_token(payload, secret: Settings.jwt_secret, algorithm: 'HS256')
    JWT.encode(payload, secret, algorithm)
  end

  let(:valid_claims) { { sub: '42', exp: Time.now.to_i + 60 } }

  describe '.issue' do
    it 'stores the user id as subject and expires after the configured TTL', :aggregate_failures do
      token = described_class.issue(42)
      payload, = JWT.decode(token, nil, false)

      expect(payload['sub']).to eq('42')
      expect(payload['exp'] - payload['iat']).to eq(Settings.jwt_ttl_seconds)
    end
  end

  describe '.verify' do
    it 'returns the user id of a valid token' do
      token = described_class.issue(42)

      expect(described_class.verify(token)).to eq(42)
    end

    context 'when the token is expired' do
      it 'rejects it' do
        token = described_class.issue(42, now: Time.now - (Settings.jwt_ttl_seconds + 60))

        expect { described_class.verify(token) }.to raise_error(TokenService::InvalidToken)
      end
    end

    context 'when the token was signed with another secret' do
      it 'rejects it' do
        token = build_token(valid_claims, secret: SecureRandom.hex(32))

        expect { described_class.verify(token) }.to raise_error(TokenService::InvalidToken)
      end
    end

    context 'when the token is unsigned (alg: none)' do
      it 'rejects it' do
        token = build_token(valid_claims, secret: nil, algorithm: 'none')

        expect { described_class.verify(token) }.to raise_error(TokenService::InvalidToken)
      end
    end

    context 'when the token has no expiration' do
      it 'rejects it' do
        token = build_token({ sub: '42' })

        expect { described_class.verify(token) }.to raise_error(TokenService::InvalidToken)
      end
    end

    context 'when the token is not a JWT' do
      it 'rejects it' do
        expect { described_class.verify('not-a-token') }.to raise_error(TokenService::InvalidToken)
      end
    end
  end
end
