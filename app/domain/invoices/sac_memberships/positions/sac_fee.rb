# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    module Positions
      class SacFee < Base

        self.group = :sac_fee
        self.balancing_payment_possible = true

        def gross_amount
          amount = beitragskategorie_fee
          amount -= config.reduction_amount.to_i if sac_fee_reduction?
          amount
        end

        private

        def sac_fee_reduction?
          config.reduction_required_membership_years.to_i.positive? &&
            person.membership_years >= config.reduction_required_membership_years
        end

      end
    end
  end
end
