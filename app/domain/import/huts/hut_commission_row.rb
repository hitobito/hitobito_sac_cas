# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Import::Huts
  class HutCommissionRow
    def self.can_process?(row)
      row[:verteilercode].to_s == "4000.0" &&
        ["SAC Clubhütte", "SAC Sektionshütte"].include?(row[:hut_category])
    end

    def initialize(row)
      @row = row
    end

    def import!
      group = group_for(@row)
      set_data(@row, group)
      group.save!
    end

    private

    def group_for(row)
      Group::SektionsKommissionHuetten.find_or_initialize_by(parent_id: parent_id(row))
    end

    def set_data(row, group)
      group.type = Group::SektionsKommissionHuetten.name
      group.name = Group::SektionsKommissionHuetten.label
      group.parent_id = parent_id(row)
    end

    def parent_id(row)
      sektion = Group::Sektion.find_by(navision_id: owner_navision_id(row))
      funktionaere = Group::SektionsFunktionaere.find_by(parent: sektion)
      Group::SektionsKommissionen.find_by(parent: funktionaere).id
    rescue
      raise "WARNING: No parent found for row #{row.inspect}"
    end

    def owner_navision_id(row)
      row[:contact_navision_id].to_s.sub(/^[0]*/, "")
    end
  end
end
