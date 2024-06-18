# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class JoinZusatzsektion < MemberJoinSectionBase

    delegate :group_for_neuanmeldung, to: :join_section

    def initialize(join_section, person, join_date, sac_family_membership: false, **params)
      super(join_section, person, join_date, **params)
      @sac_family_membership = sac_family_membership
      @created_at = Time.zone.now

      raise 'missing neuanmeldungen subgroup' unless group_for_neuanmeldung
    end

    private

    def affected_people
      sac_family_membership? ? super : [person]
    end

    def prepare_roles(person)
      group_for_neuanmeldung.roles.build(
        person: person,
        type: group_for_neuanmeldung.class.const_get('NeuanmeldungZusatzsektion'),
        beitragskategorie: derive_beitragskategorie,
        created_at: created_at,
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

    def sac_family_membership?
      @sac_family_membership
    end

    def validate_family_main_person?
      sac_family_membership?
    end

    attr_reader :group, :created_at
  end
end
