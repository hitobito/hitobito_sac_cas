# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 2
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class EintritteRow < MitgliedschaftRow
    def initialize(entry, group, range, format = nil)
      @range = range
      super(entry, group, format)
    end

    def start_on
      membership_role.start_on
    end

    def self_registration_reason
      entry.self_registration_reason&.text
    end

    def sac_is_new_entry
      membership_role.start_on == roles(*SacCas::MITGLIED_STAMMSEKTION_ROLES).first.start_on
    end

    def sac_is_section_new_entry
      membership_role == group_membership_roles.first
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

    private

    def membership_role
      @membership_role ||= group_membership_roles.find do |r|
        @range.cover?(r.start_on)
      end
    end
  end
end
