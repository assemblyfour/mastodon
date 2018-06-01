# frozen_string_literal: true

class SwlistingsValidator < ActiveModel::Validator
  def validate(status)
    return unless status.local? && !status.reblog?
    return if status.reply? || status.private_visibility? || status.direct_visibility?
    return if status.account.user&.staff?

    tags = Extractor.extract_hashtags(status.text)

    return unless tags.map(&:downcase).include? 'swlisting'

    unless status.account.avatar?
      status.errors.add(:base, 'You need a profile picture to post on the #swlisting hashtag')
    end

    swlisting_statuses = status.account.statuses
                                .tagged_with(Tag.find_by(name: 'swlisting'))
                                .without_replies
                                .without_reblogs
                                .where(Status.arel_table[:created_at].gt(1.day.ago))

    unless swlisting_statuses.count < 3
      status.errors.add(:base, 'You can only post 3 times per day to #swlisting')
    end
  end
end
