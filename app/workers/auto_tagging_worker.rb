# frozen_string_literal: true

class AutoTaggingWorker
  include Sidekiq::Worker

  def perform(status_id)
    status = Status.find(status_id)
    AutoTaggingService.new.call(status)
  rescue ActiveRecord::RecordNotFound
    true
  end
end
