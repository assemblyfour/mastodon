# frozen_string_literal: true

class MediaAnalysisService < BaseService
  NUDEBOX_URL = ENV.fetch('NUDEBOX_URL', nil)

  def call(media_attachment)
    return if media_attachment.remote_url.present?
    return unless NUDEBOX_URL
    response = Excon.post(NUDEBOX_URL,
                headers: {
                  "Content-Type" => "application/json",
                },
                body: JSON.dump({url: media_attachment.file.url(:small)})
              )
    nudity_level = JSON.parse(response.body).fetch('nude')
    meta = media_attachment.file.instance_read(:meta).merge(nudity_level: nudity_level)
    media_attachment.file.instance_write(:meta, meta)
    media_attachment.save!
  end
end
