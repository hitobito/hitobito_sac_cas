# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration::Sektion::MainPerson < SelfRegistration::MainPerson::Base
  self.required_attrs = [
    :first_name, :last_name, :email, :address, :zip_code, :town, :birthday, :country, :number
  ]

  self.attrs += [:household_key, :supplements]
  self.active_model_only_attrs += [:supplements, :household_emails]

  delegate :self_registration_reason_id, :register_on_date, :newsletter, to: :supplements,
    allow_nil: true

  public :role

  def person
    super.tap do |p|
      p.self_registration_reason_id = self_registration_reason_id
      p.privacy_policy_accepted_at = Time.zone.now if supplements&.sektion_statuten
    end
  end
end
