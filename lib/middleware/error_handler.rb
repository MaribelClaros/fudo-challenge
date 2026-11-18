# frozen_string_literal: true

require_relative '../http_error'
require_relative '../json_response'

module Middleware
  # Turns errors raised while handling a request into JSON responses:
  # - HttpError: the status and error code it carries (an expected failure, e.g. 422).
  # - Anything else: a generic 500. The details are logged, never sent to the client.
  class ErrorHandler
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue HttpError => e
      JsonResponse.build(e.status, e.to_h, e.headers)
    rescue StandardError => e
      log(env, e)
      JsonResponse.build(500, { error: 'internal_server_error' })
    end

    private

    def log(env, error)
      stream = env['rack.errors'] || $stderr
      stream.puts("[ErrorHandler] #{error.class}: #{error.message}")
      stream.puts(error.backtrace.join("\n")) if error.backtrace
    end
  end
end
