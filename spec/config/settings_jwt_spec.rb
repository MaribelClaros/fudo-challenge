# frozen_string_literal: true

RSpec.describe Settings do
  let(:valid_secret) { 'a' * Settings::MIN_JWT_SECRET_LENGTH }

  describe '.validate!' do
    context 'when JWT_SECRET is missing' do
      it 'raises naming the missing variable' do
        with_env('JWT_SECRET' => nil) do
          expect { described_class.validate! }
            .to raise_error(Settings::MissingConfigError, 'Missing required environment variables: JWT_SECRET')
        end
      end
    end

    context 'when JWT_SECRET is too short' do
      it 'raises an InvalidConfigError' do
        with_env('JWT_SECRET' => 'too-short') do
          expect { described_class.validate! }.to raise_error(Settings::InvalidConfigError, /at least 32/)
        end
      end
    end

    context 'when JWT_SECRET is long enough' do
      it 'does not raise' do
        with_env('JWT_SECRET' => valid_secret) do
          expect { described_class.validate! }.not_to raise_error
        end
      end
    end
  end

  describe '.jwt_ttl_seconds' do
    it 'defaults to one hour' do
      with_env('JWT_TTL_SECONDS' => nil) do
        expect(described_class.jwt_ttl_seconds).to eq(3600)
      end
    end
  end
end
