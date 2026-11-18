# frozen_string_literal: true

# Entry point for the Sidekiq worker process:
#   bundle exec sidekiq -r ./config/worker.rb
require_relative 'boot'
require_relative '../lib/jobs/create_product_job'
