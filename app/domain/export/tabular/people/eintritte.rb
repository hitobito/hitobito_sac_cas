# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class Eintritte < Export::Tabular::People::Mitgliedschaft
    self.attributes = [
      :id,
      :url,
      :sektion,

      :sac_is_new_entry,
      :sac_is_re_entry,
      :sac_is_section_new_entry,
      :sac_is_section_change,
      :start_on,
      :self_registration_reason,

      *Mitgliedschaft::ROLE_ATTRIBUTES,
      *Mitgliedschaft::PERSON_ATTRIBUTES
    ]

    self.styled_attrs = {
      date: [:start_on, :sac_entry_on, :sektion_entry_on, :birthday]
    }
    def people_scope
      super
        .includes(:self_registration_reason)
        .joins(:roles_unscoped)
        .where(roles: {start_on: ..Time.zone.today})
    end

    private

    def relevant_person_ids
      EintritteScope.new(@range, @group).roles.select(:person_id)
    end
  end
end
