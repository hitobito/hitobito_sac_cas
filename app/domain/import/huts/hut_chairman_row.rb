# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Import::Huts
  class HutChairmanRow
    include RemovingPlaceholderContactRole

    def self.can_process?(row)
      row[:verteilercode].to_s == "4007.0" &&
        ["SAC Clubhütte", "SAC Sektionshütte"].include?(row[:hut_category])
    end

    def initialize(row)
      @row = row
    end

    def import! # rubocop:disable Metrics/MethodLength
      person = person_for(@row)
      set_person_name(@row, person)
      group_id = group_id(@row)
      unless group_id
        # TODO fix bugs in data export, where not all huts are exported
        Rails.logger.debug { "Skipping hut chairman for unknown hut #{navision_id(@row)}" }
        return
      end
      person.roles.where(
        type: Group::SektionsFunktionaere::Huettenobmann.name,
        group_id: group_id
      ).find_each(&:really_destroy!)
      person.roles.build(
        type: Group::SektionsFunktionaere::Huettenobmann.name,
        created_at: created_at(@row),
        group_id: group_id
      )

      remove_placeholder_contact_role(person)

      person.save!
    end

    private

    def person_for(row)
      Person.find_or_initialize_by(id: owner_navision_id(row))
    end

    def set_person_name(row, person)
      person.first_name = first_name(row)
      person.last_name = last_name(row)
    end

    def group_id(row)
      Group::Sektion.find_by(navision_id: navision_id(row))
        .descendants
        .find { |child| child.type == "Group::SektionsFunktionaere" }
        .id
    rescue NoMethodError
      Rails.logger.debug {
        "Failed to find existing SektionsFunktionäre of section with " \
        "navision id #{navision_id(row)}"
      }
    end

    def navision_id(row)
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
