# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    class SalesOrder < Entity
      SOURCE_SYSTEM = "hitobito"
      BACKLOG_ID = 0
      TYPE = "Product"

      DISPATCH_TYPES = {
        print: "Letter",
        digital: "Mail"
      }.with_indifferent_access.tap { |h| h.default = "Letter" }.freeze

      DOCUMENT_CODES = {
        sac_membership_yearly: "R",
        sac_membership: "R",
        sac_membership_not_sent: "R",
        course: "RK",
        sac_magazine: "RA"
      }.with_indifferent_access.freeze

      PROCESS_FLOW_NUMBERS = {
        # membership invoice created by the yearly batch job
        sac_membership_yearly: 1,
        # membership invoice created individually
        sac_membership: 3,
        # membership invoice created individually, without sending it to member
        sac_membership_not_sent: 6,
        course: 2,
        sac_magazine: 4
      }.with_indifferent_access.freeze

      attr_reader :positions, :additional_user_fields

      def initialize(invoice, positions = [], additional_user_fields = {})
        super(invoice)
        @positions = positions
        @additional_user_fields = additional_user_fields
      end

      def abacus_key?
        entity.abacus_sales_order_key?
      end

      def abacus_key
        return nil unless abacus_key?

        {sales_order_id: entity.abacus_sales_order_key, sales_order_backlog_id: BACKLOG_ID}
      end

      def assign_abacus_key(data)
        entity.update!(abacus_sales_order_key: data.fetch(:sales_order_id), state: :open)
      end

      def set_cancelled
        entity.update!(state: :cancelled)
      end

      def full_attrs
        sales_order_attrs.merge(
          positions: positions.map.with_index do |position, index|
            sales_order_position_attrs(position, index + 1)
          end
        )
      end

      def sales_order_attrs # rubocop:todo Metrics/AbcSize
        {
          # customer id is defined to be the same as subject id
          customer_id: entity.person.abacus_subject_key,
          order_date: entity.created_at.to_date,
          delivery_date: entity.sent_at,
          invoice_date: entity.sent_at,
          invoice_value_date: entity.issued_at,
          total_amount: entity.total.to_f,
          language: entity.person.language,
          document_code_invoice: DOCUMENT_CODES.fetch(entity.invoice_kind),
          process_flow_number: PROCESS_FLOW_NUMBERS.fetch(entity.invoice_kind),
          user_fields: order_user_fields
        }
      end

      def order_user_fields
        {
          user_field1: entity.id.to_s,
          user_field2: SOURCE_SYSTEM,
          user_field3: DISPATCH_TYPES.fetch(entity.person.correspondence)
        }.merge(additional_user_fields)
      end

      def sales_order_position_attrs(position, index) # rubocop:todo Metrics/MethodLength
        {
          # not required if positions are nested in sales order
          # sales_order_id: entity.abacus_sales_order_key,
          # sales_order_backlog_id: BACKLOG_ID,
          position_number: index,
          type: TYPE,
          pricing: {
            price_after_finding: position.amount.to_f.round(2)
          },
          quantity: {
            ordered: position.count,
            charged: position.count,
            delivered: position.count
          },
          product: {
            description: position.name.to_s[0, 100],
            product_number: position.article_number.to_s[0, 100]
          },
          accounts: position_accounts_fields(position),
          user_fields: position_user_fields(position)
        }
      end

      def position_accounts_fields(position)
        fields = {}
        fields[:income_cost_centre1_id] = position.cost_center.to_i if position.cost_center
        fields[:income_cost_centre2_id] = position.cost_unit.to_i if position.cost_unit
        fields
      end

      def position_user_fields(position) # rubocop:disable Metrics/AbcSize
        # limit strings according to Abacus field lengths
        fields = {}
        fields[:user_field1] = position.grouping.to_s[0, 50] if position.grouping
        if position.other_debitor_id # amount will be billed to section
          fields[:user_field2] = position.other_debitor_id.to_i
          fields[:user_field3] = position.other_debitor_amount.to_f.round(2)
        elsif position.other_creditor_id # amount will be payed to section
          fields[:user_field2] = position.other_creditor_id.to_i
        end
        fields[:user_field4] = position.details.to_s[0, 50] if position.details.present?
        fields
      end
    end
  end
end
