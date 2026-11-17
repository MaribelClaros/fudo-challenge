# frozen_string_literal: true

MIGRATIONS_DIR = File.expand_path('db/migrations', __dir__)

namespace :db do
  task :environment do
    require_relative 'config/boot'
    Sequel.extension :migration
  end

  desc 'Run pending migrations (prefix with RACK_ENV=test for the test database)'
  task migrate: :environment do
    Sequel::Migrator.run(DB, MIGRATIONS_DIR)
    puts "#{Settings.env} database is up to date"
  end

  desc 'Create the demo user'
  task seed: :environment do
    load File.expand_path('db/seeds.rb', __dir__)
  end
end
