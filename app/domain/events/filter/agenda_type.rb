# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Events::Filter
  class AgendaType < Base
    self.permitted_args = [:values]

    TYPES = %w[
      regular_tour
      subito_tour
      regular_event
    ].freeze

    class Option
      def initialize(type)
        @type = type
      end

      def id
        @type
      end

      def to_s(format = nil)
        I18n.t("agenda.filters.types.#{@type}")
      end
    end

    OPTIONS = TYPES.map { |status| Option.new(status) }

    def initialize(*)
      super
      @args = {values: Array(@args[:values]).map(&:to_s) & TYPES}.compact_blank
    end

    def apply(scope) # rubocop:disable Metrics/MethodLength
      return scope if blank?

      condition = args[:values].map { |type| send(:"#{type}_condition") }.join(" OR ")
      scope.where(condition)
    end

    def regular_tour_condition
      "(events.type = 'Event::Tour' AND NOT events.subito)"
    end

    def subito_tour_condition
      "(events.type = 'Event::Tour' AND events.subito)"
    end

    def regular_event_condition
      "events.type IS NULL"
    end
  end
end
