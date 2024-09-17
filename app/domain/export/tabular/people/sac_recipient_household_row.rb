# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class SacRecipientHouseholdRow < SacRecipientRow
    def entry
      household.find { _1.email.present? } || household.first
    end

    def household
      # Make sure it is an array, in case someone passes in a plain non-household list
      Array.wrap(@entry)
    end

    def first_name
      return entry.first_name unless household?

      I18n.t("roles.beitragskategorie.family")
    end

    def last_name
      return entry.last_name unless household?

      Export::Tabular::People::HouseholdRow.new(household).name
    end

    def household?
      household.size > 1
    end
  end
end
