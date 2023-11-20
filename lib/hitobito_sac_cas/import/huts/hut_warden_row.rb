# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join('lib', 'import', 'xlsx_reader.rb')

module Import::Huts
  class HutWardenRow

    def self.can_process?(row)
      row[:verteilercode].to_s == '4005'
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
        #   and some hut wardens belong to things other than huts
        puts "Skipping hut warden for unknown hut #{navision_id(@row)}"
        return
      end
      person.roles.where(
        type: Group::Huette::Huettenwart.name,
        group_id: group_id,
      ).destroy_all
      person.roles.build(
        type: Group::Huette::Huettenwart.name,
        created_at: created_at(@row),
        group_id: group_id,
      )
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
      # TODO handle nonexistent group
      Group.find_by(type: Group::Huette.name, navision_id: navision_id(row)).id
    rescue NoMethodError
      puts "Failed to find existing hut with navision id #{navision_id(row)}"
    end

    def navision_id(row)
      row[:contact_navision_id].to_s.sub!(/^[0]*/, '')
    end

    def first_name(row)
      row[:related_first_name]
    end

    def last_name(row)
      row[:related_last_name]
    end

    def owner_navision_id(row)
      Integer(row[:related_navision_id].to_s.sub!(/^[0]*/, ''))
    end

    def created_at(row)
      row[:created_at]
    end
  end
end
