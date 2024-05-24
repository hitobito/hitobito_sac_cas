# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    module Positions
      class HutSolidarityFee < Base

        self.group = :sac_fee
        self.balancing_payment_possible = true

        private

        def fee_attr_prefix
          "hut_solidarity_fee_#{section.huts? ? :with : :without}_hut"
        end

      end
    end
  end
end
