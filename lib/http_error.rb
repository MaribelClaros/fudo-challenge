# frozen_string_literal: true

# An error that maps directly to an HTTP response. Raise it from anywhere while handling
# a request and Middleware::ErrorHandler turns it into a JSON error response.
#
#   raise HttpError.new(422, 'invalid_params', details: { username: 'is required' })
#   # => 422 {"error":"invalid_params","details":{"username":"is required"}}
class HttpError < StandardError
  attr_reader :status, :code, :details, :headers

  def initialize(status, code, details: nil, headers: {})
    super(code)
    @status = status
    @code = code
    @details = details
    @headers = headers
  end

  def to_h = { error: code, details: }.compact
end
