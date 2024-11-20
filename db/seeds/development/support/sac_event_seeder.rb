# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join("db", "seeds", "support", "event_seeder")

class SacEventSeeder < EventSeeder
  def course_attributes(values)
    super.merge(
      cost_center: CostCenter.first,
      cost_unit: CostUnit.first,
      language: :de,
      season: Event::Kind::SEASONS.sample,
      start_point_of_time: :day,
      contact_id: Person.last.id,
      price_member: 10,
      price_regular: 20,
      number: "#{current_year - rand(5)}-#{rand(100000)}"
    )
  end

  def current_year
    @current_year ||= Time.zone.today.year
  end
end
