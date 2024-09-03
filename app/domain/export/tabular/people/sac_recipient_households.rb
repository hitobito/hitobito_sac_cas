# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class SacRecipientHouseholds < Export::Tabular::People::SacRecipients
    self.row_class = SacRecipientHouseholdRow

    def list
      @household_list ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName @list is already used in the base-class, which shadows this extension
        people = super

        ::People::HouseholdList.new(people.includes(:primary_group))
      end
    end
  end
end
