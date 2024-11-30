# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsMitglieder < ::Group
  self.static_name = true

  ### ROLES
  class Mitglied < ::Role
    include SacCas::Role::MitgliedStammsektion

    self.terminatable = true

    validates :end_on, presence: true

    attr_readonly :family_id

    after_create_commit :transmit_data_to_abacus
    before_validation :set_family_id, if: -> { beitragskategorie&.family? && family_id.blank? }
    after_destroy :destroy_household, if: -> { person.sac_family_main_person }

    private

    def destroy_household
      person.update_columns(sac_family_main_person: false)
      Household.new(person, maintain_sac_family: false).destroy
    end

    def transmit_data_to_abacus
      Invoices::Abacus::TransmitPersonJob.new(person).enqueue! if
        person.abacus_subject_key.blank? &&
          person.data_quality != "error"
    end

    def set_family_id
      self.family_id = person.household_key
    end
  end

  class MitgliedZusatzsektion < ::Role
    include SacCas::Role::MitgliedZusatzsektion

    self.terminatable = true

    validates :end_on, presence: true

    # This is used by the import as we don't have the complete memberhip history of a person
    # but have to import MitgliedZusatzsektion roles anyway.
    attr_accessor :skip_mitglied_during_validity_period_validation
  end

  class Ehrenmitglied < ::Role
    include SacCas::Role::ActiveMembershipValidations

    self.permissions = []
    self.basic_permissions_only = true
  end

  class Beguenstigt < ::Role
    include SacCas::Role::ActiveMembershipValidations

    self.permissions = []
    self.basic_permissions_only = true
  end

  class Leserecht < ::Role
    self.permissions = [:group_and_below_read]
  end

  class Schreibrecht < ::Role
    self.permissions = [:group_and_below_full]
  end

  roles Mitglied, MitgliedZusatzsektion, Ehrenmitglied, Beguenstigt, Leserecht, Schreibrecht
end
