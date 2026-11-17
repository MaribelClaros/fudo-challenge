# frozen_string_literal: true

RSpec.describe Settings do
  describe '.validate!' do
    context 'when the database URL is set' do
      it 'does not raise' do
        with_env('TEST_DATABASE_URL' => 'postgres://localhost/fudo_test') do
          expect { described_class.validate! }.not_to raise_error
        end
      end
    end

    context 'when the database URL is missing' do
      it 'raises naming the missing variable' do
        with_env('TEST_DATABASE_URL' => nil) do
          expect { described_class.validate! }
            .to raise_error(Settings::MissingConfigError, 'Missing required environment variables: TEST_DATABASE_URL')
        end
      end
    end

    context 'when the database URL is blank' do
      it 'treats it as missing' do
        with_env('TEST_DATABASE_URL' => '   ') do
          expect { described_class.validate! }.to raise_error(Settings::MissingConfigError)
        end
      end
    end

    context 'when running outside the test environment' do
      it 'requires DATABASE_URL instead of TEST_DATABASE_URL' do
        with_env('RACK_ENV' => 'development', 'DATABASE_URL' => nil, 'TEST_DATABASE_URL' => 'postgres://localhost/x') do
          expect { described_class.validate! }
            .to raise_error(Settings::MissingConfigError, 'Missing required environment variables: DATABASE_URL')
        end
      end
    end
  end

  describe '.database_url' do
    it 'uses TEST_DATABASE_URL in the test environment' do
      with_env('TEST_DATABASE_URL' => 'postgres://localhost/fudo_test') do
        expect(described_class.database_url).to eq('postgres://localhost/fudo_test')
      end
    end
  end

  describe '.db_pool_size' do
    it 'defaults to 5' do
      with_env('DB_POOL' => nil) do
        expect(described_class.db_pool_size).to eq(5)
      end
    end

    it 'rejects non-numeric values' do
      with_env('DB_POOL' => 'abc') do
        expect { described_class.db_pool_size }.to raise_error(ArgumentError)
      end
    end
  end
end
