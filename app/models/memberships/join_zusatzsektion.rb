# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class JoinZusatzsektion < JoinBase
    delegate :group_for_neuanmeldung, to: :join_section

    attr_reader :person

    def initialize(join_section, person, sac_family_membership: false, **params)
      super(join_section, person, **params)
      @sac_family_membership = sac_family_membership

      raise "missing neuanmeldungen subgroup" unless group_for_neuanmeldung
    end

    def affected_people
      sac_family_membership? ? super : [person]
    end

    private

    def prepare_roles(person)
      group_for_neuanmeldung.roles.build(
        person: person,
        type: group_for_neuanmeldung.class.const_get(:NeuanmeldungZusatzsektion),
        beitragskategorie: derive_beitragskategorie,
        created_at: now,
        delete_on: nil
      )
    end

    def derive_beitragskategorie
      if sac_family_membership?
        :family
      else
        SacCas::Beitragskategorie::Calculator.new(person).calculate(for_sac_family: false)
      end
    end

    def validate_family_main_person?
      sac_family_membership?
    end

    def sac_family_membership?
      @sac_family_membership
    end
  end
end
