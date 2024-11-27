# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Wizards::Steps::MainEmail < Wizards::Step
  include ActiveModel::Dirty # required for ValidatedEmail
  include ValidatedEmail

  attribute :email, :string

  validates :email, presence: true
  validate :ensure_email_available

  def ensure_email_available
    return if email.blank?

    person = Person.find_by(email: email)
    if person.present? && !(current_user == person)
      errors.add(:email, I18n.t("activerecord.errors.models.person.attributes.email.taken"))
    end
  end
end
