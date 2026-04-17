# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events::Filter::Tour
  # Filter panel with three independent approval-related conditions for tours:
  # - self_approved: tours approved without any FreigabeKomitee involvement
  # - pending_at_komitee_id: tours in review with pending approvals at a specific komitee
  # - responsible_komitee_id: tours (any state) that a specific komitee is responsible for
  class Approval < ApprovalBase
    self.permitted_args = [:self_approved, :pending_at_komitee_id, :responsible_komitee_id]

    APPROVED_OR_LATER_STATES = %w[approved published ready closed canceled].freeze

    def apply(scope)
      scope = filter_self_approved(scope)
      scope = filter_pending_at_komitee(scope)
      filter_responsible_komitee(scope)
    end

    def blank?
      args[:self_approved].blank? &&
        args[:pending_at_komitee_id].blank? &&
        args[:responsible_komitee_id].blank?
    end

    private

    def filter_self_approved(scope)
      return scope if args[:self_approved].blank?

      scope
        .where(state: APPROVED_OR_LATER_STATES)
        .where(
          "NOT EXISTS (" \
            "SELECT 1 FROM event_approvals " \
            "WHERE event_approvals.event_id = events.id " \
            "AND event_approvals.freigabe_komitee_id IS NOT NULL" \
          ")"
        )
    end

    def filter_pending_at_komitee(scope)
      komitee_id = args[:pending_at_komitee_id].to_i
      return scope if komitee_id.zero?

      scope
        .where(state: :review)
        .where(Arel::Nodes::Exists.new(pending_at_komitee_subquery(komitee_id)))
    end

    def filter_responsible_komitee(scope)
      komitee_id = args[:responsible_komitee_id].to_i
      return scope if komitee_id.zero?

      scope.where(Arel::Nodes::Exists.new(responsible_komitee_subquery(komitee_id)))
    end

    def pending_at_komitee_subquery(komitee_id)
      base_responsibility_scope
        .joins("JOIN event_approval_kinds ON event_approval_kinds.deleted_at IS NULL")
        .where(freigabe_komitee_id: komitee_id)
        .where(not_yet_approved_sql)
        .select("1")
        .arel
    end

    def responsible_komitee_subquery(komitee_id)
      base_responsibility_scope
        .where(freigabe_komitee_id: komitee_id)
        .select("1")
        .arel
    end
  end
end
