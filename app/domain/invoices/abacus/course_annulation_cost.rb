# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Invoices
  module Abacus
    class CourseAnnulationCost
      # cancellation in [range] days before course start => [factor]
      CANCELLATION_COST_FACTORS = {
        ..9 => 1,
        10..19 => 0.75,
        20..30 => 0.5
      }
      CANCELLATION_PROCESSING_FEE = 80.0

      def initialize(participation)
        @participation = participation
      end

      def position_description_and_amount_cancelled
        days_until_start = (course_start_date - cancelled_at).to_i

        range = CANCELLATION_COST_FACTORS.keys.find { |range| range.include?(days_until_start) }
        if range
          factor = CANCELLATION_COST_FACTORS.fetch(range)
          [t("cancellation_costs", percentage: (factor * 100).round), cancellation_costs(factor)]
        else
          [t("processing_fee"), CANCELLATION_PROCESSING_FEE]
        end
      end

      def position_description_and_amount_absent
        [t("cancellation_costs", percentage: 100), @participation.price]
      end

      private

      def cancellation_costs(factor)
        return 0 unless @participation.price

        @participation.price * factor
      end

      def cancelled_at
        @participation.canceled_at || Time.zone.today
      end

      def course_start_date
        @course_start_date ||= @participation.event.dates.first.start_at.to_date
      end

      def t(key, **)
        I18n.t(key, scope: "invoices.course_annulation", **)
      end
    end
  end
end
