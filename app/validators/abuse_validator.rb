class AbuseValidator < ActiveModel::Validator
  def validate(status)
    return if status.account.marked_not_spam?

    if status.account.targeted_reports.unresolved.select(:account_id).distinct.count > 20
      status.errors.add(:base, "Your account has been reported to be against our ToS. Please contact support@assemblyfour.com")
    end
  end
end
