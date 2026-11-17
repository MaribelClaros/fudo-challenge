# frozen_string_literal: true

require 'json'

# Builds Rack responses with a JSON body.
module JsonResponse
  module_function

  def build(status, body, headers = {})
    [status, { 'content-type' => 'application/json' }.merge(headers), [JSON.generate(body)]]
  end
end
