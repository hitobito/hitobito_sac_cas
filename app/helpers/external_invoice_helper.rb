# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module ExternalInvoiceHelper
  def abo_magazin_invoice_possible?(person)
    person.sac_membership.recent_abonnent_magazin_roles.exists? && can?(
      :create_abo_magazin_invoice, person
    )
  end
end
