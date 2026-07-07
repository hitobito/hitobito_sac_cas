# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events
  module Tours
    class ApprovalComposer
      attr_reader :event, :user

      def initialize(event, user)
        @event = event
        @user = user
      end

      def relevant_freigabe_komitees
        if event.state.in?(Event::Tour::FREIGABE_PENDING_STATES)
          responsible_freigabe_komitees
        else
          involved_freigabe_komitees
        end
      end

      def next_relevant_pruefer
        @next_relevant_pruefer ||= begin
          person_ids = responsible_freigabe_komitees.list.flat_map do |komitee|
            kind = first_unapproved_kind_for(komitee)
            next [] unless kind
            pruefer_roles_for(komitee, kind).pluck(:person_id)
          end
          Person.where(id: person_ids)
        end
      end

      def all_pruefers
        Person.where(
          id: pruefer_roles_for(responsible_freigabe_komitees).select(:person_id)
        )
      end

      def remaining_pruefers
        all_pruefers.where.not(id: next_relevant_pruefer.select(:id))
      end

      def fetch_freigabe_komitee_activities_target_groups(komitees)
        scope =
          Event::ApprovalCommissionResponsibility
            .where(freigabe_komitee: komitees.map(&:id))
            .eager_load(target_group: :translations, activity: :translations)
        with_event_responsibilities(scope)
          .group_by(&:freigabe_komitee_id)
          .transform_values { |list| list.map { |resp| [resp.activity, resp.target_group] } }
      end

      private

      def responsible_freigabe_komitees
        groups = Group::FreigabeKomitee
          .joins(:event_approval_commission_responsibilities)
          .distinct
        with_event_responsibilities(groups)
      end

      def with_event_responsibilities(scope)
        scope.where(
          event_approval_commission_responsibilities: {
            sektion: sektion,
            subito: event.subito,
            target_group: event.main_target_groups.select(:id),
            activity: event.main_activities.select(:id)
          }
        )
      end

      def involved_freigabe_komitees
        Group::FreigabeKomitee
          .joins(:event_approvals)
          .where(event_approvals: {event_id: event.id})
          .distinct
      end

      def approved_kind_ids_for(komitee)
        event.approvals
          .where(freigabe_komitee: komitee, approved: true)
          .pluck(:approval_kind_id)
      end

      def first_unapproved_kind_for(komitee)
        approved_ids = approved_kind_ids_for(komitee)
        approval_kinds.where.not(id: approved_ids).first
      end

      def pruefer_roles_for(komitees, kind = nil)
        scope = Group::FreigabeKomitee::Pruefer.where(group: komitees)
        return scope unless kind
        scope.joins(:approval_kinds).where(event_approval_kinds: {id: kind})
      end

      def approval_kinds
        @approval_kinds ||= Event::ApprovalKind.list.without_deleted
      end

      def sektion
        @sektion ||= @event.groups.first.layer_group
      end
    end
  end
end
