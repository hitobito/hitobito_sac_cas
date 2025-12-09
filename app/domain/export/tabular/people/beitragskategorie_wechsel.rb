# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class BeitragskategorieWechsel < Export::Tabular::People::Mitgliedschaft
    self.attributes = [
      :id,
      :url,
      :sektion,

      :changed_on,
      :changed_youth_adult,
      :changed_youth_family,
      :changed_adult_family,
      :changed_family_adult,
      :changed_family_youth,

      *Mitgliedschaft::ROLE_ATTRIBUTES,
      *Mitgliedschaft::PERSON_ATTRIBUTES
    ]

    self.styled_attrs = {
      date: [:changed_on, :sac_entry_on, :sektion_entry_on, :birthday]
    }

    private

    def relevant_person_ids
      BeitragskategorieWechselScope.new(@group, @range).relevant_person_ids
    end
  end
end
