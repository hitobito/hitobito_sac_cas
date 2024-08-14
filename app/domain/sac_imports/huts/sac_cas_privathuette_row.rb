# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Huts
  class SacCasPrivathuetteRow
    def self.can_process?(row)
      row[:verteilercode] == 40000 && hut_type(row).present? && row[:contact_navision_id] == "00001000"
    end

    def self.hut_type(row)
      Group::SacCasPrivathuette if row[:hut_category] == "Privat"
    end

    def self.parent
      @parent ||= Group::SacCasPrivathuetten.first
    end

    def import!
      self.class.parent.children.find_or_create_by!(navision_id: navision_id(@row)) do |g|
        g.type = Group::SacCasPrivathuette
        g.name = @row[:related_last_name]
      end
    end
  end
end
