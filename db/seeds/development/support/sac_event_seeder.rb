# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join("db", "seeds", "support", "event_seeder")

class SacEventSeeder < EventSeeder
  def seed_sac_course(group_id)
    event = seed_event(group_id, :course)
    event.reload
    event.cost_center = CostCenter.first
    event.cost_unit = CostUnit.first
    event.language = :de
    event.season = Event::Kind::SEASONS.sample
    event.start_point_of_time = :day
    event.contact_id = fetch_contact_person.id
    event.save!
  end

  private

  def fetch_contact_person
    Person.find_by(first_name: "Linda", last_name: "Donie")
  end
end
