# frozen_string_literal: true

class REST::CredentialAccountSerializer < REST::AccountSerializer
  attributes :source
  attribute :email, if: -> { instance_options[:show_email] }

  def email
    object.user.email
  end

  def source
    user = object.user

    {
      privacy: user.setting_default_privacy,
      sensitive: user.setting_default_sensitive,
      language: user.setting_default_language,
      note: object.note,
      fields: object.fields.map(&:to_h),
    }
  end
end
