# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Filter::Tour
  class ApprovalBase < Events::Filter::Base
    self.permitted_args = [:active]

    def blank?
      !active?
    end

    private

    def active?
      args[:active].to_s == "1"
    end

    # Base scope for correlated EXISTS subqueries: matches responsibilities to the current event
    # by sektion, subito flag, target group (normalized to parent),
    # and discipline (normalized to parent).
    def base_responsibility_scope
      Event::ApprovalCommissionResponsibility
        .joins("JOIN events_groups ON events_groups.event_id = events.id")
        .joins("JOIN groups ON groups.id = events_groups.group_id")
        .where("event_approval_commission_responsibilities.sektion_id = groups.layer_group_id")
        .where("event_approval_commission_responsibilities.subito = events.subito")
        .where(target_group_id: main_target_groups_subquery)
        .where(discipline_id: main_disciplines_subquery)
    end

    def main_target_groups_subquery
      Event::TargetGroup
        .joins("JOIN events_target_groups " \
               "ON events_target_groups.target_group_id = event_target_groups.id")
        .where("events_target_groups.event_id = events.id")
        .select("COALESCE(event_target_groups.parent_id, event_target_groups.id)")
    end

    def main_disciplines_subquery
      Event::Discipline
        .joins("JOIN events_disciplines ON events_disciplines.discipline_id = event_disciplines.id")
        .where("events_disciplines.event_id = events.id")
        .select("COALESCE(event_disciplines.parent_id, event_disciplines.id)")
    end

    # Correlated subquery: the approval kind has not yet been approved for this event+komitee.
    def not_yet_approved_sql
      <<~SQL.squish
        NOT EXISTS (
          SELECT 1 FROM event_approvals
          WHERE event_approvals.event_id = events.id
            AND event_approvals.freigabe_komitee_id = event_approval_commission_responsibilities.freigabe_komitee_id
            AND event_approvals.approval_kind_id = event_approval_kinds.id
            AND event_approvals.approved = true
        )
      SQL
    end

    # Correlated subquery: no lower-order approval kind exists that is also not yet approved,
    # ensuring this kind is the current lowest open level.
    def no_lower_order_unapproved_sql
      <<~SQL.squish
        NOT EXISTS (
          SELECT 1 FROM event_approval_kinds eak_lower
          WHERE eak_lower.order < event_approval_kinds.order
            AND eak_lower.deleted_at IS NULL
            AND NOT EXISTS (
              SELECT 1 FROM event_approvals
              WHERE event_approvals.event_id = events.id
                AND event_approvals.freigabe_komitee_id = event_approval_commission_responsibilities.freigabe_komitee_id
                AND event_approvals.approval_kind_id = eak_lower.id
                AND event_approvals.approved = true
            )
        )
      SQL
    end
  end
end
