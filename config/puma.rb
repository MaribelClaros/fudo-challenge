# frozen_string_literal: true

# Requests served concurrently by each Puma process. Each thread may hold a database
# connection, so DB_POOL must be at least this number.
threads_count = Integer(ENV.fetch('PUMA_THREADS', '5'))
threads threads_count, threads_count

# Number of forked processes, to use several CPU cores. 0 runs a single process.
workers Integer(ENV.fetch('WEB_CONCURRENCY', '0'))

port Integer(ENV.fetch('PORT', '9292'))
environment ENV.fetch('RACK_ENV', 'development')
