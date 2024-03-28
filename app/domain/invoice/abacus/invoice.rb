# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Invoice
  module Abacus
    # sales order use custom sales_order_id (= hitobito Invoice#id) as identifier.
    class Invoice < Entity

      def create
        create_sales_order
        create_sales_order_positions
      end

      private

      def create_sales_order
        puts 'create order'
        # TODO: Aktuelle Meldung: Der Datensatz '10/0' konnte nicht gefunden werden. (Auftragkopf - Auftrag-Nr.)
        client.create(:sales_order, sales_order_attrs)
      end

      def create_sales_order_positions
        entity.invoice_items.list.each_with_index do |item, index|
          puts 'create position'
          client.create(:sales_order_position, sales_order_position_attrs(item, index + 1))
        end
      end

      def sales_order_attrs
        {
          sales_order_id: entity.id,
          application_id: 99,
          customer_id: 3, # selbst erstellt
          customer_subject_id: entity.recipient.abacus_key, # abacus_key attribute is yet missing on person
          order_date: entity.issued_at,
          delivery_date: entity.sent_at,
          total_amount: entity.total.to_f
        }
      end

      def sales_order_position_attrs(item, position)
        {
          sales_order_id: entity.id,
          position_number: position,
          amount: { total_including_tax: item.total },
          quantity: { charged: item.count },
          product: { description: item.name }
        }
      end

    end
  end
end
