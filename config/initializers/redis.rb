# frozen_string_literal: true

redis_connection = ConnectionPool::Wrapper.new(size: ENV.fetch('MAX_THREADS').to_i, timeout: 3) do
  Redis.new(
   url: ENV['REDIS_URL'],
    driver: :hiredis
  )
end

namespace = ENV.fetch('REDIS_NAMESPACE') { nil }

if namespace
  Redis.current = Redis::Namespace.new(namespace, redis: redis_connection)
else
  Redis.current = redis_connection
end
