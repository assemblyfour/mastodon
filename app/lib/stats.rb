class Stats
  def self.statsd
    @statsd ||= begin
      statsd = Datadog::Statsd.new(ENV['STATSD_HOST'] || 'localhost', (ENV['STATSD_PORT'] || 8125).to_i)
      statsd.namespace = 'switter'
      statsd
    end
  end

  def self.method_missing(meth, *args, **kwargs, &block)
    statsd.send(meth, *args, **kwargs, &block)
  end
end
