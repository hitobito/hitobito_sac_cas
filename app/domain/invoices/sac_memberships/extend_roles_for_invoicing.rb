# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices::SacMemberships
  class ExtendRolesForInvoicing
    ROLES_TO_EXTEND = (SacCas::MITGLIED_ROLES + [
      Group::Ehrenmitglieder::Ehrenmitglied,
      Group::SektionsMitglieder::Beguenstigt,
      Group::SektionsMitglieder::Ehrenmitglied
    ]).map(&:sti_name)

    BATCH_SIZE = 500

    def initialize(date)
      @date = date
    end

    def extend_roles
      roles_to_extend.in_batches(of: BATCH_SIZE) do |batch|
        Role.with_inactive.where(id: batch.pluck(:id)).update_all(end_on: @date)
      end
    end

    private

    def roles_to_extend
      Role.with_inactive.where(type: ROLES_TO_EXTEND, terminated: false, end_on: ...@date, person_id: person_ids)
    end

    def person_ids
      Person.joins(:roles_unscoped)
        .where(roles: {type: Group::SektionsMitglieder::Mitglied.sti_name, terminated: false, end_on: ..@date})
        .where.not(id: ExternalInvoice::SacMembership.where(year: @date.year).select(:person_id))
        .where.not(data_quality: :error)
        .select(:id)
    end
  end
end
