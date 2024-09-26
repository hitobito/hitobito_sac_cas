# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join("db", "seeds", "support", "event_seeder")

class SacEventSeeder < EventSeeder
  def seed_sac_course(group_id)
    event = seed_event(group_id, :course)
    event.update!(
      cost_center: CostCenter.first,
      cost_unit: CostUnit.first,
      language: :de,
      season: Event::Kind::SEASONS.sample,
      start_point_of_time: :day,
      contact_id: Person.last.id,
      price_member: 10,
      price_regular: 20
    )
    event
  end

  def seed_sac_course_with_assignment_closed(group_id)
    seed_sac_course(group_id).update_column(:state, :assignment_closed)
  end
end
