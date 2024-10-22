# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module Abacus
    class CourseParticipationInvoice
      attr_reader :participation

      delegate :event, to: :participation

      def initialize(participation)
        @participation = participation
      end

      def positions
        return [] unless invoice?

        description, amount = position_description_and_amount
        name = [description, event.kind.level].compact_blank.join(" - ")
        @positions ||= [Invoices::Abacus::InvoicePosition.new(
          name: name, grouping: name, amount: amount, count: 1,
          article_number: article_number,
          cost_center: event.kind.cost_center.code,
          cost_unit: event.kind.cost_unit.code
        )]
      end

      def additional_user_fields
        return {} unless invoice?

        {
          user_field8: event.number,
          user_field9: event.name,
          user_field10: event_dates_label
        }
      end

      def total
        positions.sum(&:amount)
      end

      def invoice?
        !participation.price.to_i.zero?
      end

      private

      def course_start_date
        @course_start_date ||= event.dates.first.start_at.to_date
      end

      def event_dates_label
        event.dates.map do |date|
          "#{date.start_at.strftime("%d.%m.%Y")} - #{date.finish_at&.strftime("%d.%m.%Y")}"
        end.join(", ")
      end

      def article_number
        SacMembershipConfig.active(course_start_date).course_fee_article_number
      end

      def position_description_and_amount
        description = participation.price_category? ? Event::Course.human_attribute_name(participation.price_category) : nil
        [description, participation.price]
      end
    end
  end
end
