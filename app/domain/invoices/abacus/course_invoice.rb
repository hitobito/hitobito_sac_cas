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
      end

      def positions
        @positions ||= [Invoices::Abacus::InvoicePosition.new(
          name: "#{I18n.t(participation.price_category, scope: "activerecord.attributes.event/participation.price_category")} - #{participation.event.kind.level}",
          grouping: "#{I18n.t(participation.price_category, scope: "activerecord.attributes.event/participation.price_category")} - #{participation.event.kind.level}",
          amount: participation.price,
          count: 1,
          article_number: SacMembershipConfig.active(participation.event.dates.order(:start_at).first.start_at).course_fee_article_number,
          cost_center: participation.event.kind.cost_center.code,
          cost_unit: participation.event.kind.cost_unit.code
        )]
      end

      def additional_user_fields
        fields = {}
        fields[:user_field8] = participation.event.number if invoice?
        fields[:user_field9] = participation.event.name if invoice?
        fields[:user_field10] = participation.event.dates.map { |date| "#{date.start_at.strftime("%d.%m.%Y")} - #{date.finish_at&.strftime("%d.%m.%Y")}" }.join(", ") if invoice?
        fields
      end

      def total
        positions.sum(&:amount)
      end

      def invoice?
        positions.any?(&:amount)
      end
    end
  end
end
