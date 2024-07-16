# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join("lib", "import", "xlsx_reader.rb")

module Import::Huts
  class HutWardenRow
    def self.can_process?(row)
      row[:verteilercode].to_s == "4005.0" && self.role_type_for(row).present?
    end

    def initialize(row)
      @row = row
    end

    def import! # rubocop:disable Metrics/MethodLength
      person = person_for(@row)
      set_person_name(@row, person)
      role_type = self.role_type_for(@row)
      huette = huette(@row)
      unless huette
        # TODO fix bugs in data export, where not all huts are exported
        #   and some hut wardens belong to things other than huts
        Rails.logger.debug { "Skipping hut warden for unknown hut #{huette_navision_id(@row)}" }
        return
      end
      person.roles.where(
        type: role_type.name,
        group_id: huette.id
      ).destroy_all
      person.roles.build(
        type: role_type.name,
        created_at: created_at(@row),
        group_id: huette.id
      )
      person.save!
    end

    private

    def person_for(row)
      Person.find_or_initialize_by(id: owner_navision_id(row))
    end

    def self.role_type_for(row)
      case row[:hut_category]
      when "SAC Sektionshütte"
        Group::Sektionshuette::Huettenwart
      when "SAC Clubhütte"
        Group::SektionsClubhuette::Huettenwart
      end
    end

    def set_person_name(row, person)
      person.first_name = first_name(row)
      person.last_name = last_name(row)
    end

    def huette(row)
      # TODO handle nonexistent group
      @huette ||= Group.find_by(navision_id: huette_navision_id(row))
    rescue NoMethodError
      Rails.logger.debug { "Failed to find existing hut with navision id #{huette_navision_id(row)}" }
    end

    def huette_navision_id(row)
      row[:contact_navision_id].to_s.sub(/^[0]*/, "")
    end

    def first_name(row)
      row[:related_first_name]
    end

    def last_name(row)
      row[:related_last_name]
    end

    def owner_navision_id(row)
      Integer(row[:related_navision_id].to_s.sub(/^[0]*/, ""))
    end

    def created_at(row)
      row[:created_at]
    end
  end
end
