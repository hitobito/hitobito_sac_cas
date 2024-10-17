# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module Abacus
    class CourseInvoice
      attr_reader :participation

      def initialize(participation)
        @participation = participation
        @course = participation.event
        @amount = participation.price || 0
      end

      def positions
        grouping = "#{Event::Course.human_attribute_name(@participation.price_category) if @participation.price_category?} - #{@course.kind.level}"
        name = @participation.canceled_at? ? canceled_name : grouping

        @positions ||= [Invoices::Abacus::InvoicePosition.new(
          name:, grouping:, amount: @amount, count: 1,
          article_number: SacMembershipConfig.active(course_start_date).course_fee_article_number,
          cost_center: @course.kind.cost_center.code,
          cost_unit: @course.kind.cost_unit.code
        )]
      end

      def additional_user_fields
        return {} unless invoice?

        {
          user_field8: @course.number,
          user_field9: @course.name,
          user_field10: @course.dates.map do |date|
            "#{date.start_at.strftime("%d.%m.%Y")} - #{date.finish_at&.strftime("%d.%m.%Y")}"
          end.join(", ")
        }
      end

      def total
        positions.first.amount
      end

      def invoice?
        positions.first.amount != 0
      end

      private

      def course_start_date
        @course_start_date ||= @course.dates.order(:start_at).first.start_at.to_date
      end

      def canceled_name
        days_until_start = (course_start_date - @participation.canceled_at).to_i

        description, @amount = if days_until_start > 30
          [t("processing_fee"), 80]
        elsif days_until_start >= 20
          [t("cancellation_costs", percentage: 50), @amount * 0.5]
        elsif days_until_start >= 10
          [t("cancellation_costs", percentage: 75), @amount * 0.75]
        else
          [t("cancellation_costs", percentage: 100), @amount]
        end

        t("position_name", description:, level: @course.kind.level)
      end

      def t(key, **)
        I18n.t(key, scope: "people.course_invoices", **)
      end
    end
  end
end
