# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Migrations
  class ProcessLeftOverMembershipInvoicesFrom2025 < BaseJob
    def perform
      scope.find_each do |invoice|
        Invoices::SacMemberships::MembershipManager
          .new(invoice.person, invoice.link, invoice.year)
          .update_membership_status
      end
    end

    private

    def scope
      ExternalInvoice::SacMembership
        .payed
        .includes(:person)
        .where(year: 2025, updated_at: Time.zone.local(2026).all_year)
    end
  end
end
