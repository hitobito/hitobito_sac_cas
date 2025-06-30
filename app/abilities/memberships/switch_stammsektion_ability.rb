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
      permission(:any).may(:create).on_main_person_if_backoffice?
    end

    on(Wizards::Memberships::SwitchStammZusatzsektion) do
      permission(:any).may(:create).on_main_person_with_zusatzsektion_if_backoffice?
    end

    def on_main_person_if_backoffice? = backoffice? && sac_membership.stammsektion_role.present? && person.sac_family_main_person?

    def on_main_person_with_zusatzsektion_if_backoffice?
      sac_membership.zusatzsektion_roles.any? && on_main_person_if_backoffice?
    end
  end
end
