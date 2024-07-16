# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    class SalesOrderInterface
      TYPE_OF_PRINTING = "AccToSequentialControl"

      def initialize(client = nil)
        @client = client
      end

      def create(sales_order)
        data = create_request(sales_order)
        sales_order.assign_abacus_key(data)
        trigger_next_step(sales_order.abacus_key)
        true
      end

      # creates a batch of sales orders, but without triggering the next step.
      # (this happens manually in abacus)
      def create_batch(sales_orders)
        batch_response = create_batch_request(sales_orders)
        assign_abacus_sales_order_keys(sales_orders, batch_response)
        batch_response
      end

      def fetch(abacus_key)
        return unless abacus_key

        client.get(:sales_order, abacus_key, "$expand" => "Positions")
      end

      def cancel(sales_order)
        client.update(:sales_order, sales_order.abacus_key, {user_fields: {user_field21: true}})
        sales_order.set_cancelled
      end

      private

      def create_batch_request(sales_orders)
        client.batch do
          sales_orders.each do |order|
            create_request(order)
          end
        end
      end

      def create_request(sales_order)
        client.create(:sales_order, sales_order.full_attrs)
      end

      def trigger_next_step(abacus_key)
        return unless abacus_key

        path = "#{client.endpoint(:sales_order, abacus_key)}/" \
               "ch.abacus.orde.TriggerSalesOrderNextStep"
        client.request(:post, path, {type_of_printing: TYPE_OF_PRINTING})
      end

      def delete(abacus_key)
        return unless abacus_key

        client.delete(:sales_order, abacus_key)
      rescue
        # ignore error
      end

      def assign_abacus_sales_order_keys(sales_orders, batch_response)
        sales_orders.each_with_index do |order, index|
          part = batch_response.parts[index]
          order.assign_abacus_key(part.json) if part&.created?
        end
      end

      def client
        @client ||= Client.new
      end
    end
  end
end
