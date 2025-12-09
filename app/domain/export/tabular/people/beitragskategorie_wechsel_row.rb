# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 2
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class BeitragskategorieWechselRow < MitgliedschaftRow
    def initialize(entry, group, range, format = nil)
      @range = range
      super(entry, group, format)
    end

    def changed_on
      membership_role.start_on
    end

    def changed_youth_adult
      previous_membership_role.youth? && membership_role.adult?
    end

    def changed_youth_family
      previous_membership_role.youth? && membership_role.family?
    end

    def changed_adult_family
      previous_membership_role.adult? && membership_role.family?
    end

    def changed_family_adult
      previous_membership_role.family? && membership_role.adult?
    end

    def changed_family_youth
      previous_membership_role.family? && membership_role.youth?
    end

    private

    def membership_role
      @membership_role ||= descending_membership_roles.find do |r|
        @range.cover?(r.start_on)
      end
    end

    def previous_membership_role
      @previous_membership_role ||= descending_membership_roles.find do |r|
        @range.cover?(r.end_on + 1.day)
      end
    end

    def descending_membership_roles
      @descending_membership_roles ||= group_membership_roles.reverse
    end
  end
end
