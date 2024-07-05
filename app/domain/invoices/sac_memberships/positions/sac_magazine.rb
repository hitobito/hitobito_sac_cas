# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    module Positions
      class SacMagazine < Base
        self.group = :sac_fee
        self.section_payment_possible = true

        def article_number
          config.magazine_fee_article_number
        end

        private

        def fee_attr_prefix
          :magazine_fee
        end
      end
    end
  end
end
