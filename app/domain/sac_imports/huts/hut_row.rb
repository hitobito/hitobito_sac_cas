# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Huts
  class HutRow
    def self.can_process?(row)
      row[:verteilercode] == 4000 && hut_type(row).present? &&
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

    def self.hut_type(row)
      case row[:hut_category]
      when "SAC Sektionshütte"
        Group::Sektionshuette
      when "SAC Clubhütte"
        Group::SektionsClubhuette
      end
    end

    def self.parent_group_type(row)
      case row[:hut_category]
      when "SAC Sektionshütte"
        Group::Sektionshuetten
      when "SAC Clubhütte"
        Group::SektionsClubhuetten
      end
    end

    private

    def group_for(row)
      self.class.hut_type(row).find_or_initialize_by(navision_id: navision_id(row))
    end

    def set_data(row, group)
      group.type = self.class.hut_type(row).name
      group.name = name(row)
      group.parent_id = parent_id(row)
    end

    def navision_id(row)
      row[:related_navision_id].to_s.sub(/^[0]*/, "")
    end

    def name(row)
      row[:related_last_name]
    end

    def parent_id(row)
      sektion = Group.find_by(navision_id: owner_navision_id(row))
      funktionaere = Group::SektionsFunktionaere.find_by(parent: sektion)
      self.class.parent_group_type(row).find_by(parent: funktionaere).id
    rescue
      raise "WARNING: No parent found for row #{row.inspect}. Descendants: #{sektion.descendants.inspect}"
    end

    def owner_navision_id(row)
      row[:contact_navision_id].to_s.sub(/^[0]*/, "")
    end
  end
end