# frozen_string_literal: true

require_relative 'http_error'

# Cursor (keyset) pagination over a dataset's id column.
#
#   GET /products?limit=20             first page
#   GET /products?limit=20&after=42    the page after the record with id 42
#
# Unlike OFFSET, the cost of a page doesn't grow with how deep it is: the database jumps
# straight to `id > after` through an index.
module Pagination
  DEFAULT_LIMIT = 20
  MAX_LIMIT = 100
  MAX_ID = (2**63) - 1 # largest PostgreSQL bigint

  Page = Data.define(:records, :next_cursor)

  module_function

  def paginate(dataset, params)
    limit, after = parse(params)
    dataset = dataset.where(Sequel[:id] > after) if after
    # One extra record tells whether there is a next page without a COUNT query.
    records = dataset.order(:id).limit(limit + 1).all
    return Page.new(records:, next_cursor: nil) if records.size <= limit

    Page.new(records: records.first(limit), next_cursor: records[limit - 1].id.to_s)
  end

  def parse(params)
    errors = {}
    limit = parse_limit(params['limit'], errors)
    after = parse_after(params['after'], errors)
    raise HttpError.new(422, 'invalid_params', details: errors) if errors.any?

    [limit, after]
  end

  def parse_limit(value, errors)
    return DEFAULT_LIMIT if value.nil?

    limit = integer(value)
    return limit if limit&.between?(1, MAX_LIMIT)

    errors['limit'] = "must be an integer between 1 and #{MAX_LIMIT}"
    nil
  end

  def parse_after(value, errors)
    return nil if value.nil?

    after = integer(value)
    return after if after&.between?(1, MAX_ID)

    errors['after'] = 'must be a cursor returned as next_cursor'
    nil
  end

  def integer(value) = value.is_a?(String) ? Integer(value, 10, exception: false) : nil
end
