# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    class SalesOrder < Entity

      SOURCE_SYSTEM = 'hitobito'
      BACKLOG_ID = 0
      TYPE = 'Product'
      TYPE_OF_PRINTING = 'AccToSequentialControl'
      INVOICE_KINDS = {
        membership: 'R',
        course: 'C'
      }.with_indifferent_access.freeze

      def create(positions, additional_user_fields: {})
        create_sales_order(additional_user_fields: additional_user_fields)
        create_sales_order_positions(positions)
        # does not work currently, abraxas is investigating
        trigger_sales_order rescue nil # rubocop:disable Style/RescueModifier
      rescue => e
        delete_sales_order
        raise e
      end

      def fetch
        client.get(:sales_order, abacus_id, '$expand' => 'Positions')
      end

      private

      def create_sales_order(additional_user_fields: {})
        attrs = sales_order_attrs(additional_user_fields: additional_user_fields)
        data = client.create(:sales_order, attrs)
        entity.abacus_sales_order_key = data.fetch(:sales_order_id)
      end

      def create_sales_order_positions(positions)
        positions.each_with_index do |position, index|
          client.create(:sales_order_position, sales_order_position_attrs(position, index + 1))
        end
      end

      def trigger_sales_order
        path = "#{client.endpoint(:sales_order, abacus_id)}/" \
               'ch.abacus.orde.TriggerSalesOrderNextStep'
        client.request(:post, path, { type_of_printing: TYPE_OF_PRINTING })
      end

      def delete_sales_order
        return unless entity.abacus_sales_order_key

        client.delete(:sales_order, abacus_id)
      rescue
        # ignore error
      end

      def abacus_id
        { sales_order_id: entity.abacus_sales_order_key, sales_order_backlog_id: BACKLOG_ID }
      end

      def sales_order_attrs(additional_user_fields: {})
        {
          # customer id is defined to be the same as subject id
          customer_id: entity.recipient.abacus_subject_key,
          order_date: entity.issued_at,
          delivery_date: entity.sent_at,
          total_amount: entity.total.to_f,
          document_code_invoice: INVOICE_KINDS[entity.invoice_kind],
          language: entity.recipient.language,
          user_fields: order_user_fields(additional_user_fields)
        }
      end

      def order_user_fields(additional_user_fields)
        {
          user_field1: entity.id.to_s,
          user_field2: SOURCE_SYSTEM,
          user_field3: entity.recipient.correspondence == 'digital'
        }.merge(additional_user_fields)
      end

      def sales_order_position_attrs(position, index) # rubocop:disable Metrics/MethodLength
        {
          sales_order_id: entity.abacus_sales_order_key,
          sales_order_backlog_id: BACKLOG_ID,
          position_number: index,
          type: TYPE,
          pricing: { price_after_finding: position.amount.to_f.round(2) },
          quantity: { ordered: position.count, charged: position.count, delivered: position.count },
          product: { description: position.name, product_number: position.article_number.to_s },
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
