# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 2
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class EintritteRow < Export::Tabular::Row
    include CommonSektionPersonRowBehaviour

    def initialize(entry, group, range, format = nil)
      @range = range
      super(entry, group, format)
    end

    def sac_is_new_entry
      roles(*SacCas::MITGLIED_STAMMSEKTION_ROLES) == [membership_role] ||
        all_covered?(SacCas::MITGLIED_STAMMSEKTION_ROLES)
    end

    def sac_is_re_entry
      return false unless membership_role.is_a?(Group::SektionsMitglieder::Mitglied)

      prior_roles =
        (roles(*SacCas::MITGLIED_STAMMSEKTION_ROLES) - [membership_role])
          .select { |r| r.start_on < @range.begin }

      prior_roles.any? && prior_roles.none? { |r| r.active?(membership_role.start_on - 1.day) }
    end

    def sac_is_section_new_entry
      roles_in_group(*SacCas::MITGLIED_ROLES) == [membership_role] ||
        all_covered?(SacCas::MITGLIED_ROLES)
    end

    def sac_is_section_change
      !roles(*SacCas::MITGLIED_STAMMSEKTION_ROLES).last(2).map(&:group_id).uniq.one?
    end

    private

    def all_covered?(role_types)
      roles(*role_types).all? { |r| @range.cover?(r.start_on) }
    end
  end
end
