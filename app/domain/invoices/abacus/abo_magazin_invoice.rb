# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module Abacus
    class AboMagazinInvoice
      attr_reader :abonnent_role

      delegate :person, to: :abonnent_role

      def initialize(abonnent_role)
        @abonnent_role = abonnent_role
      end

      def positions
        @positions ||= build_positions
      end

      def total
        positions.sum(&:amount)
      end

      def additional_user_fields
        {}
      end

      def invoice?
        sac_cas_group.abo_alpen_fee_article_number &&
          sac_cas_group.abo_alpen_fee &&
          sac_cas_group.abo_alpen_postage_abroad
      end

      private

      def build_positions
        positions = [main_fee_position]
        positions << abroad_fee_position if person.living_abroad?
        positions
      end

      def main_fee_position
        Invoices::Abacus::InvoicePosition.new(
          name: fee_position_name,
          grouping: fee_position_name,
          article_number: sac_cas_group.abo_alpen_fee_article_number,
          amount: sac_cas_group.abo_alpen_fee,
          count: 1
        )
      end

      def abroad_fee_position
        Invoices::Abacus::InvoicePosition.new(
          name: abroad_fee_position_name,
          grouping: abroad_fee_position_name,
          article_number: sac_cas_group.abo_alpen_fee_article_number,
          amount: sac_cas_group.abo_alpen_postage_abroad,
          count: 1
        )
      end

      def fee_position_name
        I18n.t("invoices.abo_magazin.positions.abo_fee",
          group: abonnent_role.group,
          time_period: new_role_period,
          locale: person.language)
      end

      def abroad_fee_position_name
        I18n.t("invoices.abo_magazin.positions.abroad_fee",
          group: abonnent_role.group,
          locale: person.language)
      end

      def new_role_period
        start_date = abonnent_role.end_on + 1.day
        end_date = abonnent_role.end_on + 1.year
        "#{I18n.l(start_date)} - #{I18n.l(end_date)}"
      end

      def sac_cas_group = @sac_cas_group = Group.root
    end
  end
end
