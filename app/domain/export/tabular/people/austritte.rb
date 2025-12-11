# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class Austritte < Export::Tabular::People::Mitgliedschaft
    self.attributes = [
      :id,
      :url,
      :sektion,

      :sac_is_terminated,
      :sac_is_section_change,
      :end_on,
      :termination_reason,
      :data_retention_consent,

      *Mitgliedschaft::ROLE_ATTRIBUTES,
      *Mitgliedschaft::PERSON_ATTRIBUTES
    ]

    self.styled_attrs = {
      date: [:sac_entry_on, :sektion_entry_on, :end_on, :birthday]
    }

    private

    def relevant_person_ids
      Export::Tabular::People::AustritteScope.new(group, @range).roles.select(:person_id)
    end
  end
end
