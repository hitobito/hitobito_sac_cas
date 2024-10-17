# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module Abacus
    class CourseAnnulationInvoice < CourseParticipationInvoice
      CANCELLATION_PROCESSING_FEE = 80.0

      # cancellation in [range] days before course start => [factor]
      CANCELLATION_COST_FACTORS = {
        ..9 => 1,
        10..19 => 0.75,
        20..30 => 0.5
      }

      def additional_user_fields
        return {} unless invoice?

        super.merge(user_field22: replaced_abacus_key)
      end

      private

      def position_description_and_amount
        case participation.state
        when "canceled" then position_description_and_amount_canceled
        when "absent" then position_description_and_amount_absent
        else raise InvalidArgumentError, "participation must be canceled or absent for annulation invoice"
        end
      end

      def position_description_and_amount_canceled
        days_until_start = (course_start_date - participation.canceled_at).to_i

        range = CANCELLATION_COST_FACTORS.keys.find { |range| range.include?(days_until_start) }
        if range
          factor = CANCELLATION_COST_FACTORS.fetch(range)
          [t("cancellation_costs", percentage: (factor * 100).round), participation.price * factor]
        else
          [t("processing_fee"), CANCELLATION_PROCESSING_FEE]
        end
      end

      def position_description_and_amount_absent
        [t("cancellation_costs", percentage: 100), participation.price]
      end

      def replaced_abacus_key
        ExternalInvoice::CourseParticipation
          .where(link: participation)
          .order(created_at: :desc)
          .pick(:abacus_sales_order_key)
      end

      def t(key, **)
        I18n.t(key, scope: "invoices.course_annulation", **)
      end
    end
  end
end
