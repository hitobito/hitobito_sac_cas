# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices::SacMemberships
  class ExtendRolesForInvoicing
    ROLES_TO_EXTEND = SacCas::MITGLIED_ROLES + [
      Group::Ehrenmitglieder::Ehrenmitglied,
      Group::SektionsMitglieder::Beguenstigt,
      Group::SektionsMitglieder::Ehrenmitglied
    ]

    def initialize(date)
      @date = date
    end

    def extend_roles
      Person.joins(:roles)
        .where(roles: member_role_deleted_before_date)
        .where.not(id: person_ids_with_invoice_in_year)
        .where.not(data_quality: :error)
        .find_each do |person|
        person.roles.where(type: ROLES_TO_EXTEND).find_each do |role|
          role.update_attribute(:delete_on, @date)
        end
      end
    end

    private

    def person_ids_with_invoice_in_year
      ExternalInvoice::SacMembership.where(year: @date.year).select(:person_id)
    end

    def member_role_deleted_before_date
      {type: Group::SektionsMitglieder::Mitglied.sti_name, terminated: false, delete_on: ..@date}
    end
  end
end
