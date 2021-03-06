# frozen_string_literal: true

class BlockWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'critical'

  def perform(account_id, target_account_id)
    AfterBlockService.new.call(Account.find(account_id), Account.find(target_account_id))
  end
end
