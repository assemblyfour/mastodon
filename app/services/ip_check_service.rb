# frozen_string_literal: true

class IPCheckService < BaseService
  IP_CHECK_URL = ENV.fetch('IP_CHECK_URL', nil)

  DEFAULT = {
    allowed: 3,
    country: 'unknown'
  }
  def call(ip)
    return DEFAULT.clone unless IP_CHECK_URL
    response = Excon.get("#{IP_CHECK_URL}/#{ip}",
                headers: {
                  "Content-Type" => "application/json",
                },
                expects: [200],
                retries: 3
              )
    body = JSON.parse(response.body)
    {
      allowed: body.fetch('allowed'),
      country: body.fetch('country')
    }
  rescue Excon::Errors::HTTPStatusError, KeyError
    DEFAULT.clone
  end
end
