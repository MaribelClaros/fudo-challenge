# frozen_string_literal: true

require_relative '../lib/models/user'

username = ENV.fetch('SEED_USERNAME', 'demo')
password = ENV.fetch('SEED_PASSWORD', 'demo-password')

if User.where(username:).empty?
  user = User.new(username:)
  user.password = password
  user.save
  puts "Created user '#{username}'"
else
  puts "User '#{username}' already exists, skipping"
end
