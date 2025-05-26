# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Huts
  class HutsRow < Row
    def can_process?
      row[:verteilercode] == 4000 && group_type.present? &&
        row[:contact_navision_id] != "00001000"
    end

    def import!
      group = group_type.find_or_initialize_by(parent_id: parent_id)
      group.type = group_type.name
      group.name = group_type.label
      group.parent_id = parent_id
      group.save!
    end

    private

    def group_type
      case row[:hut_category]
      when "SAC Sektionshütte"
        Group::Sektionshuetten
      when "SAC Clubhütte"
        Group::SektionsClubhuetten
      end
    end

    def parent_id
      sektion = Group.find_by(navision_id: owner_navision_id)
      Group::SektionsFunktionaere.find_by(parent: sektion).id
    rescue
      raise "WARNING: No parent found for row #{row.inspect}"
    end

    def owner_navision_id
      row[:contact_navision_id].to_s.sub(/^[0]*/, "")
    end
  end
end
