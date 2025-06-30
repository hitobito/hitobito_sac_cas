# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Memberships
  class SwitchStammZusatzsektion < SwitchStammsektion
    def groups
      zusatzsektion_layer_ids = person.sac_membership.zusatzsektion_roles.joins(:group)
        .where(beitragskategorie: person.sac_membership.stammsektion_role.beitragskategorie)
        .map { |r| r.group.layer_group_id }

      Group.where(id: zusatzsektion_layer_ids).select(:id, :name)
    end

    def switch_operation
      @switch_operation ||= Memberships::SwitchStammZusatzsektion.new(choose_sektion.group, person)
    end

    private

    # NOTE: noop, we we dont want to send emails
    def send_confirmation_mail(...)
    end
  end
end
