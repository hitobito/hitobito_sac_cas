# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Events::Filter
  class AgendaStatus < Base
    self.permitted_args = [:values]

    STATUSES = %w[
      published
      application_open
      application_waiting
      application_closed
      closed
      canceled
    ].freeze

    class Option
      def initialize(status)
        @status = status
      end

      def id
        @status
      end

      def to_s(format = nil)
        I18n.t("agenda.status.#{@status}")
      end
    end

    OPTIONS = STATUSES.map { |status| Option.new(status) }

    def initialize(*)
      super
      @args = {values: Array(@args[:values]).map(&:to_s) & STATUSES}.compact_blank
    end

    def apply(scope) # rubocop:disable Metrics/MethodLength
      return scope if blank?

      scope.where(
        <<~SQL.squish,
          (CASE
          WHEN events.type = 'Event::Tour' AND events.state IS DISTINCT FROM 'published'
            THEN CASE WHEN events.state = 'ready' THEN 'application_closed' ELSE events.state END
          ELSE (
            CASE
              WHEN events.application_opening_at > :today THEN 'published'
              WHEN (events.application_opening_at IS NULL OR
                    events.application_opening_at <= :today)
                AND (events.application_closing_at IS NULL OR
                     events.application_closing_at >= :today)
                THEN CASE
                  WHEN COALESCE(events.maximum_participants, 0) = 0
                    OR COALESCE(events.participant_count, 0) < events.maximum_participants
                    OR NOT events.display_booking_info
                  THEN 'application_open'
                  ELSE 'application_waiting'
                END
              ELSE 'application_closed'
            END)
          END
          ) IN (:statuses)
        SQL
        today: Time.zone.today,
        statuses: args[:values]
      )
    end
  end
end
