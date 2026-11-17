# frozen_string_literal: true

require 'rack'
require_relative 'json_response'

# Minimal Rack-compatible router.
# Matches requests by HTTP verb and path, supporting named params like "/products/:id".
class Router
  Route = Data.define(:verb, :pattern, :handler)

  def initialize(&block)
    @routes = []
    instance_eval(&block) if block
  end

  def get(path, to:) = add('GET', path, to)

  def call(env)
    request = Rack::Request.new(env)
    matches = matching_routes(request.path_info)
    return JsonResponse.build(404, { error: 'not_found' }) if matches.empty?

    route, match = matches.find { |candidate, _| candidate.verb == request.request_method }
    return method_not_allowed(matches) unless route

    route.handler.call(request, match.named_captures)
  end

  private

  # "/products/:id" => /\A\/products\/(?<id>[^\/]+)\z/
  def add(verb, path, handler)
    regex = path.gsub(/:(\w+)/, '(?<\1>[^/]+)')
    @routes << Route.new(verb, /\A#{regex}\z/, handler)
  end

  def matching_routes(path)
    @routes.filter_map do |route|
      match = route.pattern.match(path)
      [route, match] if match
    end
  end

  def method_not_allowed(matches)
    allowed = matches.map { |route, _| route.verb }.uniq.join(', ')
    JsonResponse.build(405, { error: 'method_not_allowed' }, { 'allow' => allowed })
  end
end
