# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Import::Huts
  class HutsRow
    def self.can_process?(row)
      row[:verteilercode] == 4000 && group_type(row).present? &&
        row[:contact_navision_id] != "00001000"
    end

    def initialize(row)
      @row = row
    end

    def import!
      group = group_for(@row)
      set_data(@row, group)
      group.save!
    end

    def self.group_type(row)
      case row[:hut_category]
      when "SAC Sektionshütte"
        Group::Sektionshuetten
      when "SAC Clubhütte"
        Group::SektionsClubhuetten
      end
    end

    private

    def group_for(row)
      self.class.group_type(row).find_or_initialize_by(parent_id: parent_id(row))
    end

    def set_data(row, group)
      group.type = self.class.group_type(row).name
      group.name = self.class.group_type(row).label
      group.parent_id = parent_id(row)
    end

    def parent_id(row)
      sektion = Group.find_by(navision_id: owner_navision_id(row))
      Group::SektionsFunktionaere.find_by(parent: sektion).id
    rescue
      raise "WARNING: No parent found for row #{row.inspect}"
    end

    def owner_navision_id(row)
      row[:contact_navision_id].to_s.sub(/^[0]*/, "")
    end
  end
end
