ActiveModelSerializers.config.tap do |config|
  config.default_includes = '**'
  ActiveSupport::Notifications.unsubscribe(ActiveModelSerializers::Logging::RENDER_EVENT)
end
