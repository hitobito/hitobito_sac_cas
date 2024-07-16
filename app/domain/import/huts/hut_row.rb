# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join("lib", "import", "xlsx_reader.rb")

module Import::Huts
  class HutRow
    def self.can_process?(row)
      row[:verteilercode].to_s == "4000V" && hut_type(row).present?
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
      Group.find_or_initialize_by(navision_id: navision_id(row))
    end

    def set_data(row, group)
      group.type = hut_type(row).name
      group.name = name(row)
      group.parent_id = parent_id(row)
    end

    def navision_id(row)
      row[:contact_navision_id].to_s.sub(/^[0]*/, "")
    end

    def name(row)
      row[:related_last_name]
    end

    def parent_id(row)
      Group::Sektion.find_by(navision_id: owner_navision_id(row))
        .descendants
        .find { |child| child.type == parent_group_type(row).name }
        .id
    rescue
      raise "WARNING: No parent found for row #{row.inspect}"
    end

    def owner_navision_id(row)
      row[:related_navision_id].to_s.sub(/^[0]*/, "")
    end
  end
end
