# frozen_string_literal: true

class DuplicatePostsValidator < ActiveModel::Validator
  def validate(status)
    return unless status.local? && !status.reblog?
    return if status.account.user&.staff?

    recent_statuses = status.account.statuses
                                      .recent
                                      .without_reblogs
                                      .limit(10)
                                      .select { |s| s.created_at > 1.day.ago } # no index on created_at
                                      .pluck(:text).map do |text|
      strip_hashtags_and_mentions(text)
    end


    if recent_statuses.include?(strip_hashtags_and_mentions(status.text))
      status.errors.add(:base, 'You have already posted this status recently.')
    end
  end

  def strip_hashtags_and_mentions(text)
    text.gsub(/[#@][a-z@.]+/i, '').strip
  end
end
