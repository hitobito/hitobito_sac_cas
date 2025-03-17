# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module Abacus
    class CourseAnnulationInvoice < CourseParticipationInvoice
      def additional_user_fields
        return {} unless invoice?

        super.merge(user_field22: replaced_abacus_key)
      end

      private

      def position_description_and_amount
        case participation.state
        when "canceled" then course_annulation_cost.position_description_and_amount_cancelled
        when "absent" then course_annulation_cost.position_description_and_amount_absent
        else raise InvalidArgumentError, "participation must be canceled or absent for annulation invoice"
        end
      end

      def course_annulation_cost
        @course_annulation_cost ||= CourseAnnulationCost.new(participation, @custom_price)
      end

      def replaced_abacus_key
        ExternalInvoice::CourseParticipation
          .where(link: participation)
          .order(created_at: :desc)
          .pick(:abacus_sales_order_key)
      end
    end
  end
end
