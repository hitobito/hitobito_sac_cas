# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    module Positions
      class SectionFee < Base
        def gross_amount
          return 0 if section_fee_exemption?

          amount = beitragskategorie_fee(section)
          amount -= section.reduction_amount.to_i if section.reduction?(member)
          amount
        end

        def creditor
          section
        end
      end
    end
  end
end
