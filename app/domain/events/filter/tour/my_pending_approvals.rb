# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Filter::Tour
  # Filters tours in "review" state where the current user is a Prüfer/in for
  # the lowest still-open approval level in a responsible FreigabeKomitee.
  class MyPendingApprovals < ApprovalBase
    def apply(scope)
      scope
        .where(state: "review")
        .where(Arel::Nodes::Exists.new(pending_approval_subquery))
    end

    private

    def pending_approval_subquery
      base_responsibility_scope
        .joins("JOIN event_approval_kinds ON event_approval_kinds.deleted_at IS NULL")
        .where(not_yet_approved_sql)
        .where(no_lower_order_unapproved_sql)
        .where(Arel::Nodes::Exists.new(user_responsible_for_kind_subquery))
        .select("1")
        .arel
    end

    # Correlated subquery: the current user has an active Prüfer role in the FreigabeKomitee
    # that covers this specific approval kind.
    def user_responsible_for_kind_subquery
      Group::FreigabeKomitee::Pruefer
        .joins("JOIN roles_event_approval_kinds ON roles_event_approval_kinds.role_id = roles.id")
        .where("roles.group_id = event_approval_commission_responsibilities.freigabe_komitee_id")
        .where("roles_event_approval_kinds.approval_kind_id = event_approval_kinds.id")
        .where(person_id: Auth.current_person.id)
        .merge(Role.active)
        .merge(Role.without_archived)
        .select("1")
        .arel
    end
  end
end
