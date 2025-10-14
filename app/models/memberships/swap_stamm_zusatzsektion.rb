# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class SwapStammZusatzsektion < SwitchStammsektion
    private

    def prepare_roles(person)
      super do |previous_stammsektion_role|
        # rubocop:todo Layout/LineLength
        prev_zusatzsektion_role = person.sac_membership.zusatzsektion_roles.find_by(group: membership_group)
        # rubocop:enable Layout/LineLength
        mark_for_termination(prev_zusatzsektion_role) if prev_zusatzsektion_role

        if prev_zusatzsektion_role && previous_stammsektion_role
          new_zusatzsektion_role = build_role(
            previous_stammsektion_role.group,
            Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
            person,
            previous_stammsektion_role&.beitragskategorie || calculate_beitrags_kategorie(person),
            previous_stammsektion_role&.end_on_was
          )
        end

        [prev_zusatzsektion_role, new_zusatzsektion_role]
      end
    end

    # NOTE: noop, as person _is_ member if joins section (i.e. zusatzsektion)
    def assert_person_not_member_of_join_section # noop
    end
  end
end
