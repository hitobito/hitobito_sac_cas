# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class ExternalInvoice::SacMembership < ExternalInvoice
  # link is currently a Group::Section or Group::Ortsgruppe object
  # this is not definitively defined yet, it might become a Role object as well
  # depending on the requirements for updating roles once an invoice is payed.

  def to_s
    I18n.t("invoices.sac_memberships.title", year: year)
  end
end
