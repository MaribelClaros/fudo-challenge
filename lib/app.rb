# frozen_string_literal: true

require 'rack'
require_relative 'router'
require_relative 'middleware/error_handler'
require_relative 'middleware/authentication'
require_relative 'controllers/health'
require_relative 'controllers/auth'
require_relative 'controllers/products'
require_relative 'controllers/product_requests'
require_relative 'controllers/authors'

# Builds the Rack application: middleware stack + routes.
module App
  module_function

  def build
    Rack::Builder.app do
      use Rack::Deflater
      use Middleware::ErrorHandler
      use Rack::ConditionalGet
      use Middleware::Authentication
      run App.router
    end
  end

  def router
    Router.new do
      get '/health', to: Controllers::Health.method(:show)
      post '/auth', to: Controllers::Auth.method(:create)
      get '/products', to: Controllers::Products.method(:index)
      post '/products', to: Controllers::Products.method(:create)
      get '/products/requests/:id', to: Controllers::ProductRequests.method(:show)
      get '/AUTHORS', to: Controllers::Authors.method(:show)
    end
  end
end
