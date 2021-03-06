# frozen_string_literal: true

class Auth::RegistrationsController < Devise::RegistrationsController
  layout :determine_layout

  before_action :check_enabled_registrations, only: [:new, :create]
  before_action :check_ip_address, only: [:create]
  before_action :configure_sign_up_params, only: [:create]
  before_action :set_sessions, only: [:edit, :update]
  before_action :set_instance_presenter, only: [:new, :create, :update]

  def destroy
    not_found
  end

  protected

  MAX_SUSPENSIONS_FROM_IP = 2

  def check_ip_address
    ip_data = IPCheckService.new.call(request.ip)
    allowed = ip_data[:allowed]
    tags = ["country:#{ip_data[:country]}"]
    Stats.increment('users.new.attempt', tags: tags)

    if allowed.zero? || User.confirmed.joins(:account).with_recent_ip_address(request.ip).where('accounts.suspended = true OR accounts.silenced = true').where('users.created_at > ?', 1.month.ago).count >= MAX_SUSPENSIONS_FROM_IP
      Stats.increment('users.new.suspended_ip', tags: tags)
      flash[:error] = "Your IP has been suspended. If you believe this is an error, please email support@assemblyfour.com and include 'My IP is: #{request.ip}' in the email."
      redirect_to new_user_registration_path
    elsif User.where('created_at > ?', 1.day.ago).with_recent_ip_address(request.ip).count >= allowed
      Stats.increment('users.new.duplicate_ip', tags: tags)
      flash[:error] = "There has been too many sign ups from this IP. Please try again later. If you believe this is an error, please email support@assemblyfour.com and include 'My IP is: #{request.ip}' in the email."
      redirect_to new_user_registration_path
    end
  end

  def update_resource(resource, params)
    params[:password] = nil if Devise.pam_authentication && resource.encrypted_password.blank?
    super
  end

  def build_resource(hash = nil)
    super(hash)

    resource.locale      = I18n.locale
    resource.invite_code = params[:invite_code] if resource.invite_code.blank?

    resource.build_account if resource.account.nil?
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up) do |u|
      u.permit({ account_attributes: [:username] }, :email, :password, :password_confirmation, :invite_code)
    end
  end

  def after_sign_up_path_for(_resource)
    new_user_session_path
  end

  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end

  def after_update_path_for(_resource)
    edit_user_registration_path
  end

  def check_enabled_registrations
    redirect_to root_path if single_user_mode? || !allowed_registrations?
  end

  def allowed_registrations?
    Setting.open_registrations || (invite_code.present? && Invite.find_by(code: invite_code)&.valid_for_use?)
  end

  def invite_code
    if params[:user]
      params[:user][:invite_code]
    else
      params[:invite_code]
    end
  end

  private

  def set_instance_presenter
    @instance_presenter = InstancePresenter.new
  end

  def determine_layout
    %w(edit update).include?(action_name) ? 'admin' : 'auth'
  end

  def set_sessions
    @sessions = current_user.session_activations
  end
end
