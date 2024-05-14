# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration::Abo::MainPerson < SelfRegistration::AboBasicLogin::MainPerson

  MIN_YEARS = 18

  self.required_attrs = [
    :first_name, :last_name, :email, :street, :housenumber, :zip_code,
    :town, :birthday, :country, :number
  ]
  self.attrs += [:address_care_of, :postbox]

  attribute :newsletter, :boolean
  self.active_model_only_attrs += [:newsletter]

  validate :assert_old_enough, if: -> { person.years }

  private

  def assert_old_enough
    errors.add(:base, :must_be_older_than_18) if person.years < MIN_YEARS # rubocop:disable Naming/VariableNumber
  end
end
