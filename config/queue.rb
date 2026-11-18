# frozen_string_literal: true

require 'sidekiq'

# The API only enqueues jobs (client); the worker process runs them (server). Both talk to Redis.
Sidekiq.configure_client do |config|
  config.redis = { url: Settings.redis_url }
end

Sidekiq.configure_server do |config|
  config.redis = { url: Settings.redis_url }
  # Look for due scheduled jobs about every second instead of every ~5 seconds,
  # so a job scheduled 5 seconds ahead runs close to 5 seconds later.
  config.average_scheduled_poll_interval = 1
end
