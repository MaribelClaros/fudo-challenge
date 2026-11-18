# frozen_string_literal: true

require 'json'
require_relative 'http_error'

# Reads and parses a JSON object from a request body, rejecting anything else
# with the appropriate HTTP error.
module JsonBody
  MAX_BYTES = 16 * 1024

  module_function

  def parse(request)
    raise HttpError.new(415, 'unsupported_media_type') unless request.media_type == 'application/json'

    data = JSON.parse(read_body(request))
    raise HttpError.new(400, 'invalid_json') unless data.is_a?(Hash)

    data
  rescue JSON::ParserError
    raise HttpError.new(400, 'invalid_json')
  end

  def read_body(request)
    raw = request.body&.read(MAX_BYTES + 1) || ''
    raise HttpError.new(413, 'payload_too_large') if raw.bytesize > MAX_BYTES

    raw
  end
end
