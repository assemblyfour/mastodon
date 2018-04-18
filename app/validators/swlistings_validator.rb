# frozen_string_literal: true

class SwlistingsValidator < ActiveModel::Validator
  def validate(status)
    return unless status.local? && !status.reblog?

    tags = Extractor.extract_hashtags(status.text)

    return unless tags.map(&:downcase).include? 'swlisting'

    unless status.account.avatar?
      status.errors.add(:text, 'You need a profile picture to post on the #swlisting hashtag')
    end

    swlisting_statuses = Status.where(account: status.account)
                                .where(Status.arel_table[:created_at].gt(1.day.ago))
                                .joins(:tags)
                                .where(statuses_tags: { tag: Tag.where(name: 'swlisting') })

    unless swlisting_statuses.count < 2
      status.errors.add(:text, 'You can only post 2 times per day to #swlisting')
    end
  end
end
