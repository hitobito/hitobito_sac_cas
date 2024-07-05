# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::Neuanmeldungen::Promoter
  class PaidInvoiceCondition < Condition
    def satisfied?
      paid_invoice?
    end

    private

    def paid_invoice?
      # To be implemented in the future with a separate ticket
      true
    end
  end
end
