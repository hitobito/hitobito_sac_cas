# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Migrations
  class AddBeitragskategorieToMembershipExternalInvoicesJob < BaseJob
    def perform
      ExternalInvoice::SacMembership.includes(person: :roles).find_each do |external_invoice|
        next if external_invoice.person.blank?

        external_invoice.set_beitragskategorie
        external_invoice.save
      end
    end
  end
end
