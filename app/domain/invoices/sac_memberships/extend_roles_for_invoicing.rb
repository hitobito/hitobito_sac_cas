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
    ].map(&:sti_name)

    def initialize(date)
      @date = date
    end

    def extend_roles
      role_ids = Role.where(type: ROLES_TO_EXTEND, terminated: false, delete_on: ...@date, person_id: person_ids).pluck(:id)

      Role.where(id: role_ids).update_all(delete_on: @date) if role_ids.present?
    end

    private

    def person_ids
      Person.joins(:roles)
        .where(roles: {type: Group::SektionsMitglieder::Mitglied.sti_name, terminated: false, delete_on: ...@date})
        .where.not(id: ExternalInvoice::SacMembership.where(year: @date.year).select(:person_id))
        .where.not(data_quality: :error)
        .select(:id)
    end
  end
end
