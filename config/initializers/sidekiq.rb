# frozen_string_literal: true

namespace = ENV.fetch('REDIS_NAMESPACE') { nil }
redis_params = { url: ENV['REDIS_URL'] }

if namespace
  redis_params [:namespace] = namespace
end

Sidekiq.configure_server do |config|
  config.redis = redis_params

  config.server_middleware do |chain|
    chain.add SidekiqErrorHandler
    chain.add(Sidekiq::Middleware::Server::Datadog, tags: ["app:switter"], no_host_tag: true)
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_params
end
