# frozen_string_literal: true

class AutoTaggingService < BaseService
  AUTO_TAGGER_URL = ENV.fetch('AUTO_TAGGER_URL', nil)

  def call(status)
    return unless AUTO_TAGGER_URL
    return unless status.public_visibility?
    response = Excon.post(AUTO_TAGGER_URL,
                headers: {
                  "Content-Type" => "application/json",
                },
                body: JSON.dump({text: status.text})
              )
    tags = JSON.parse(response.body).fetch('tags')
    existing_tags = status.tags.pluck(:name)

    changed = false
    tags.map { |str| str.mb_chars.downcase }.uniq(&:to_s).each do |tag|
      next if existing_tags.include?(tag)
      status.tags << Tag.where(name: tag).first_or_initialize(name: tag)
      changed = true
    end

    status.update(sensitive: true) if tags.include?('nsfw')

    if changed
      status.text_will_change!
      status.save! # trigger update callbacks
    end
  end
end
