# frozen_string_literal: true

class MediaAnalysisWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'realtime'

  def perform(media_attachment_id)
    media_attachment = MediaAttachment.find(media_attachment_id)
    MediaAnalysisService.new.call(media_attachment)
  rescue ActiveRecord::RecordNotFound
    true
  end
end
