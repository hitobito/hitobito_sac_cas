# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Xlsx::MitgliederStatistics
  class SectionActive < Section
    self.groupings = [:gender, :language, :age, :beitragskategorie]

    private

    def scope
      Role
        .active(date)
        .joins(:person)
        .where(group_id: group.id, type: SacCas::MITGLIED_ROLES.map(&:sti_name))
    end
  end
end
