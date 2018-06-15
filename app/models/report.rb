# frozen_string_literal: true
# == Schema Information
#
# Table name: reports
#
#  id                         :integer          not null, primary key
#  status_ids                 :integer          default([]), not null, is an Array
#  comment                    :text             default(""), not null
#  action_taken               :boolean          default(FALSE), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  account_id                 :integer          not null
#  action_taken_by_account_id :integer
#  target_account_id          :integer          not null
#  assigned_account_id        :integer
#

class Report < ApplicationRecord
  belongs_to :account
  belongs_to :target_account, class_name: 'Account'
  belongs_to :action_taken_by_account, class_name: 'Account', optional: true
  belongs_to :assigned_account, class_name: 'Account', optional: true

  has_one :target_account_user, class_name: 'User', through: :target_account, source: :user

  has_many :notes, class_name: 'ReportNote', foreign_key: :report_id, inverse_of: :report, dependent: :destroy

  scope :unresolved, -> { where(action_taken: false) }
  scope :resolved,   -> { where(action_taken: true) }

  validates :comment, length: { maximum: 1000 }

  def object_type
    :flag
  end

  def statuses
    Status.where(id: status_ids).includes(:account, :media_attachments, :mentions)
  end

  def media_attachments
    MediaAttachment.where(status_id: status_ids)
  end

  def assign_to_self!(current_account)
    update!(assigned_account_id: current_account.id)
  end

  def unassign!
    update!(assigned_account_id: nil)
  end

  def resolve!(acting_account, note: nil)
    target_account.targeted_moderation_notes.create!(account: acting_account, content: note) if note

    update!(action_taken: true, action_taken_by_account_id: acting_account.id)
  end

  def unresolve!
    update!(action_taken: false, action_taken_by_account_id: nil)
  end

  def unresolved?
    !action_taken?
  end

  def history
    time_range = created_at..updated_at

    sql = [
      Admin::ActionLog.where(
        target_type: 'Report',
        target_id: id,
        created_at: time_range
      ).unscope(:order),

      Admin::ActionLog.where(
        target_type: 'Account',
        target_id: target_account_id,
        created_at: time_range
      ).unscope(:order),

      Admin::ActionLog.where(
        target_type: 'Status',
        target_id: status_ids,
        created_at: time_range
      ).unscope(:order),
    ].map { |query| "(#{query.to_sql})" }.join(' UNION ALL ')

    Admin::ActionLog.from("(#{sql}) AS admin_action_logs")
  end
end
