# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Events
  module Tours
    class ApprovalComposer
      FREIGABE_PENDING_STATES = %w[draft review].freeze

      attr_reader :event, :user

      def initialize(event, user)
        @event = event
        @user = user
      end

      def relevant_freigabe_komitees
        if event.state.in?(FREIGABE_PENDING_STATES)
          responsible_freigabe_komitees
        else
          involved_freigabe_komitees
        end
      end

      def fetch_freigabe_komitee_disciplines_target_groups(komitees)
        scope =
          Event::ApprovalCommissionResponsibility
            .where(freigabe_komitee: komitees.map(&:id))
            .eager_load(target_group: :translations, discipline: :translations)
        with_event_responsibilities(scope)
          .group_by(&:freigabe_komitee_id)
          .transform_values { |list| list.map { |resp| [resp.discipline, resp.target_group] } }
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
            discipline: event.main_disciplines.select(:id)
          }
        )
      end

      def involved_freigabe_komitees
        Group::FreigabeKomitee
          .joins(:event_approvals)
          .where(event_approvals: {event_id: event.id})
          .distinct
      end

      def sektion
        @sektion ||= @event.groups.first.layer_group
      end
    end
  end
end
