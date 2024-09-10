module SacCas::People::Wso2LegacyPassword
  extend ActiveSupport::Concern

  included do
    before_save :clear_legacy_password_attributes, if: :can_clear_legacy_password_attributes?

    Person::INTERNAL_ATTRS.concat([:wso2_legacy_password_hash, :wso2_legacy_password_salt])
  end

  def valid_password?(password)
    return super if password?

    if legacy_password_valid?(password)
      update_to_devise_password!(password)
      true
    else
      false
    end
  end

  private

  def wso2_legacy_password?
    wso2_legacy_password_hash.present? &&
      wso2_legacy_password_salt.present?
  end

  def legacy_password_valid?(password)
    return false if password.blank?
    return false unless wso2_legacy_password_hash.present? && wso2_legacy_password_salt.present?
    digest_input = "#{password}#{wso2_legacy_password_salt}"
    Base64.encode64(Digest::SHA256.digest(digest_input)).strip == wso2_legacy_password_hash
  end

  def update_to_devise_password!(new_password)
    # Avoid validation of password length:
    update!(encrypted_password: Devise::Encryptor.digest(self.class, new_password))
    clear_legacy_password_attributes
  end

  def clear_legacy_password_attributes
    if can_clear_legacy_password_attributes?
      self.wso2_legacy_password_hash = nil
      self.wso2_legacy_password_salt = nil
    end
  end

  def can_clear_legacy_password_attributes?
    wso2_legacy_password_hash.present? && wso2_legacy_password_salt.present? && encrypted_password.present?
  end
end
