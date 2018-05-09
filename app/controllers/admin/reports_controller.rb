# frozen_string_literal: true

module Admin
  class TempSuspend
    include ActiveModel::Model
    attr_accessor :days, :reason
  end

  class ReportsController < BaseController
    before_action :set_report, except: [:index]

    def index
      authorize :report, :index?
      @reports = filtered_reports.page(params[:page])
    end

    def show
      authorize @report, :show?
      @report_note = @report.notes.new
      @report_notes = @report.notes.latest
      @report_history = @report.history
      @form = Form::StatusBatch.new
    end

    def update
      authorize @report, :update?
      process_report

      if @report.action_taken?
        redirect_to admin_reports_path, notice: I18n.t('admin.reports.resolved_msg')
      else
        redirect_to admin_report_path(@report)
      end
    end

    private

    def process_report
      case params[:outcome].to_s
      when 'assign_to_self'
        @report.update!(assigned_account_id: current_account.id)
        log_action :assigned_to_self, @report
      when 'unassign'
        @report.update!(assigned_account_id: nil)
        log_action :unassigned, @report
      when 'reopen'
        @report.unresolve!
        log_action :reopen, @report
      when 'resolve'
        @report.resolve!(current_account)
        log_action :resolve, @report
      when 'temp_suspend'
        @report.resolve!(current_account)
        log_action :resolve, @report
        log_action :temp_suspend, @report.target_account
        days = params[:admin_temp_suspend][:days].to_i
        reason = params[:admin_temp_suspend][:reason]
        @report.target_account.update!(suspended_until: days.days.from_now, suspension_reason: reason)
        @current_account.report_notes.create!(report: @report, content: "Temporarily suspend account for #{days} days for: #{reason}")
      when 'undo_temp_suspend'
        log_action :unsuspend_account, @report.target_account
        @report.target_account.update!(suspended_until: nil, suspension_reason: nil)
        @current_account.report_notes.create!(report: @report, content: "Unsuspended account.")

      when 'suspend'
        Admin::SuspensionWorker.perform_async(@report.target_account.id)

        log_action :resolve, @report
        log_action :suspend, @report.target_account

        resolve_all_target_account_reports
      when 'silence'
        @report.target_account.update!(silenced: true)

        log_action :resolve, @report
        log_action :silence, @report.target_account

        resolve_all_target_account_reports
      else
        raise ActiveRecord::RecordNotFound
      end
      @report.reload
    end

    def resolve_all_target_account_reports
      unresolved_reports_for_target_account.update_all(action_taken: true, action_taken_by_account_id: current_account.id)
    end

    def unresolved_reports_for_target_account
      Report.where(
        target_account: @report.target_account
      ).unresolved
    end

    def filtered_reports
      ReportFilter.new(filter_params).results.order(id: :desc).includes(
        :account,
        :target_account
      )
    end

    def filter_params
      params.permit(
        :account_id,
        :resolved,
        :target_account_id
      )
    end

    def set_report
      @report = Report.find(params[:id])
    end
  end
end
