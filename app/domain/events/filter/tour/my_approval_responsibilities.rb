# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Filter::Tour
  # Filters tours (regardless of state) that belong to a responsible FreigabeKomitee
  # where the current user has any Prüfer/in role.
  class MyApprovalResponsibilities < ApprovalBase
    def apply(scope)
      scope.where(Arel::Nodes::Exists.new(responsible_komitee_subquery))
    end

    private

    def responsible_komitee_subquery
      base_responsibility_scope
        .joins("JOIN roles ON " \
          "roles.group_id = event_approval_commission_responsibilities.freigabe_komitee_id")
        .where(roles: {type: Group::FreigabeKomitee::Pruefer.sti_name,
                       person_id: Auth.current_person.id})
        .merge(Role.active)
        .merge(Role.without_archived)
        .select("1")
        .arel
    end
  end
end
