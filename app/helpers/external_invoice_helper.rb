# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module ExternalInvoiceHelper
  def abo_magazin_invoice_possible?(person)
    (person.roles.with_inactive.where(type: Group::AboMagazin::Abonnent.sti_name).where("end_on >= ? OR end_on IS NULL", 11.months.ago.to_date).present? || person.roles.where(type: Group::AboMagazin::Neuanmeldung.sti_name).present?) && can?(:create_abo_magazin_invoice, person)
  end
end
