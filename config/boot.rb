# frozen_string_literal: true

ENV["RACK_ENV"] ||= "development"

require "bundler/setup"

if %w[development test].include?(ENV["RACK_ENV"])
  require "dotenv"
  Dotenv.load(File.expand_path("../.env", __dir__))
end

require_relative "settings"
Settings.validate!

require_relative "database"