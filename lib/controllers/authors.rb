# frozen_string_literal: true

require 'digest'
require 'time'

module Controllers
  # GET /AUTHORS: the static AUTHORS file. Clients and proxies may cache it for 24 hours.
  module Authors
    PATH = File.expand_path('../../AUTHORS', __dir__)
    MAX_AGE_SECONDS = 24 * 60 * 60

    module_function

    def show(_request, _params)
      body = File.read(PATH)
      [200, headers_for(body), [body]]
    end

    # ETag and Last-Modified let clients revalidate with If-None-Match / If-Modified-Since
    # and get an empty 304 instead of the whole file once their 24 hours are up.
    def headers_for(body)
      {
        'content-type' => 'text/plain; charset=utf-8',
        'cache-control' => "public, max-age=#{MAX_AGE_SECONDS}",
        'etag' => %("#{Digest::SHA256.hexdigest(body)}"),
        'last-modified' => File.mtime(PATH).httpdate
      }
    end
  end
end
