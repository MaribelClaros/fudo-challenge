# frozen_string_literal: true

require 'rack'
require_relative 'router'
require_relative 'controllers/health'

# Builds the Rack application: middleware stack + routes.
module App
  module_function

  def build
    Rack::Builder.app do
      use Rack::Deflater
      run App.router
    end
  end

  def router
    Router.new do
      get '/health', to: Controllers::Health.method(:show)
    end
  end
end
