# frozen_string_literal: true

class REST::CredentialAccountSerializer < REST::AccountSerializer
  attributes :source
  attribute :email, if: -> { scope.scopes.exists?('email') }

  def email
    object.user.email
  end

  def source
    user = object.user
    {
      privacy: user.setting_default_privacy,
      sensitive: user.setting_default_sensitive,
      note: object.note,
    }
  end
end
