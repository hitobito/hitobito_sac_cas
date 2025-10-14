# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

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
    # Avoid person validations to prevent validating invalid records on sign_in
    update_columns(
      encrypted_password: Devise::Encryptor.digest(self.class, new_password),
      correspondence: confirmed_at? ? :digital : :print
    )
    clear_legacy_password_attributes
  end

  def clear_legacy_password_attributes
    if can_clear_legacy_password_attributes?
      self.wso2_legacy_password_hash = nil
      self.wso2_legacy_password_salt = nil
    end
  end

  def can_clear_legacy_password_attributes?
    # rubocop:todo Layout/LineLength
    wso2_legacy_password_hash.present? && wso2_legacy_password_salt.present? && encrypted_password.present?
    # rubocop:enable Layout/LineLength
  end
end
