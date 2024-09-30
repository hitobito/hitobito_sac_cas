# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Wizards::Steps::MainEmail < Wizards::Step
  include ValidatedEmail

  attribute :email, :string

  validates :email, presence: true
  validate :ensure_email_available

  # #email_changed? is used in `ValidatedEmail` to determine if the email
  # should be validated. Here it should only be validated if the email is
  # present.
  def email_changed?
    email.present?
  end

  def ensure_email_available
    return if email.blank?

    person = Person.find_by(email: email)
    if person.present? && !(current_user == person)
      errors.add(:email, I18n.t("activerecord.errors.models.person.attributes.email.taken"))
    end
  end
end
