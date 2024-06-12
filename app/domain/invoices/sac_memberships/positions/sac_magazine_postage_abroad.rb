# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    module Positions
      class SacMagazinePostageAbroad < Base

        self.section_payment_possible = true

        def active?
          abroad_postage? && member.sac_magazine?
        end

        def gross_amount
          config.magazine_postage_abroad
        end

        def article_number
          config.magazine_postage_abroad_article_number
        end

      end
    end
  end
end
