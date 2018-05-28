# frozen_string_literal: true

class BootstrapTimelineWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'critical'

  def perform(account_id)
    BootstrapTimelineService.new.call(Account.find(account_id))
  end
end
