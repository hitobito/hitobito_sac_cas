# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Xlsx::MitgliederStatistics
  class SectionActive < Section
    self.groupings = [:gender, :language, :age, :beitragskategorie, :membership_years]

    private

    def scope
      Export::Tabular::People::AktiveScope
        .new(reference_date, group, relevant_role_types:)
        .roles
        .joins(:person)
    end
  end
end
