# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Huts
  class SacCasClubhuetteRow < HutRow
    def self.can_process?(row)
      row[:verteilercode] == 40000 && row[:contact_navision_id] == "00001000" && hut_type(row).present?
    end

    def self.hut_type(row)
      Group::SacCasClubhuette if row[:hut_category] == "SAC Clubhütte"
    end

    def self.parent
      @parent ||= Group::SacCasClubhuetten.first
    end

    def import!
      self.class.parent.children.find_or_create_by!(navision_id: navision_id(@row)) do |g|
        g.type = Group::SacCasClubhuette
        g.name = @row[:related_last_name]
      end
    end
  end
end
