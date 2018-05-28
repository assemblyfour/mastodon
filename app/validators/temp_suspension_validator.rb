# frozen_string_literal: true

class TempSuspensionValidator < ActiveModel::Validator
  include ActionView::Helpers::DateHelper

  def validate(status)
    account = status.account
    return if account.suspended_until.nil?
    if account.suspended_until > Time.now
      time_left = distance_of_time_in_words_to_now(account.suspended_until)
      status.errors.add(:base, "Your account is suspended for another #{time_left}. Reason: #{account.suspension_reason}")
    end
  end
end
