# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    class InvoicePosition

      attr_accessor :name, :grouping, :amount, :count, :article_number,
                    :other_creditor_id, :other_debitor_id, :other_debitor_amount,
                    :details, :cost_center, :cost_unit

      def initialize(attributes = {})
        @count = 1
        attributes.each do |k, v|
          send("#{k}=", v)
        end
      end

    end
  end
end
