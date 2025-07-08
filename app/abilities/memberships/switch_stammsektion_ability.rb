# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class SwitchStammsektionAbility < AbilityDsl::Base
    include Memberships::Constraints

    delegate :person, to: :subject
    delegate :sac_membership, to: :person

    on(Wizards::Memberships::SwitchStammsektion) do
      permission(:any).may(:create).on_active_member_if_backoffice?
    end

    on(Wizards::Memberships::SwapStammZusatzsektion) do
      permission(:any).may(:create).on_main_active_member_with_zusatzsektion_if_backoffice?
    end

    # NOTE: as inheritance is respected by cancancan (SwitchStammZusatzsektion.is_a?(SwitchStammsektion))
    # we have to check the instance to get the customization we want
    def on_active_member_if_backoffice?
      if subject.instance_of?(Wizards::Memberships::SwitchStammsektion)
        backoffice? && sac_membership.stammsektion_role.present?
      end
    end

    def on_main_active_member_with_zusatzsektion_if_backoffice?
      if subject.instance_of?(Wizards::Memberships::SwapStammZusatzsektion)
        backoffice? && sac_membership.stammsektion_role.present? && sac_membership.zusatzsektion_roles.any? &&
          (!sac_membership.family? || person.sac_family_main_person?)
      end
    end
  end
end
