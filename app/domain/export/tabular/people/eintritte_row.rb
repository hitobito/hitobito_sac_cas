# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 2
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class EintritteRow < SektionPersonRow
    def initialize(entry, group, range, format = nil)
      @range = range
      super(entry, group, format)
    end

    def sac_is_new_entry
      membership_role == roles(*SacCas::MITGLIED_STAMMSEKTION_ROLES).first
    end

    def sac_is_section_new_entry
      membership_role == roles_in_group(*SacCas::MITGLIED_ROLES).first
    end

    def sac_is_section_change
      !roles(*SacCas::MITGLIED_STAMMSEKTION_ROLES)
        .select { |r| r.start_on < @range.end }
        .last(2).map(&:group_id).uniq.one?
    end

    def sac_is_re_entry
      prior_roles =
        (roles(*SacCas::MITGLIED_STAMMSEKTION_ROLES) - [membership_role])
          .select { |r| r.start_on < @range.begin }

      prior_roles.any? && prior_roles.none? { |r| r.active?(membership_role.start_on - 1.day) }
    end
  end
end
