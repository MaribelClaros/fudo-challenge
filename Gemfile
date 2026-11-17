# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

gem 'bcrypt' # password hashing
gem 'pg'     # PostgreSQL driver
gem 'puma'   # web server
gem 'rack'   # web server interface
gem 'rake'   # task runner (migrations, seeds)
gem 'sequel' # database toolkit and migrations

group :development do
  gem 'irb', '~> 1.19' # interactive console (bin/console)
end

group :development, :test do
  gem 'dotenv', '~> 3.2'              # loads .env in local environments
  gem 'rubocop', require: false       # linter
  gem 'rubocop-rspec', require: false # RSpec-specific lint rules
end

group :test do
  gem 'rack-test' # sends HTTP requests to the Rack app in specs
  gem 'rspec'     # test framework
end
