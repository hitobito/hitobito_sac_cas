# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    module Positions
      class SectionEntryFee < Base
        def gross_amount
          beitragskategorie_fee(section)
        end

        def creditor
          section
        end

        def discount_factor
          1.0 # no discounts on entry fees
        end
      end
    end
  end
end
