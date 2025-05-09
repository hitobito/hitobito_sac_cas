# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

Fabricator(:sac_course, from: :course) do
  kind_id { ActiveRecord::FixtureSet.identify(:ski_course) }
  number { sequence(:number, 10000) }
end

Fabricator(:sac_open_course, from: :sac_course) do
  state { :application_open }
  contact_id { ActiveRecord::FixtureSet.identify(:admin) }
  cost_center_id { ActiveRecord::FixtureSet.identify(:tour) }
  cost_unit_id { ActiveRecord::FixtureSet.identify(:ski) }
  location { Faker::Lorem.words.join }
  description { Faker::Lorem.words.join }
  number { sequence(:number, 1000) }
  language { "de" }
  season { "winter" }
  start_point_of_time { "day" }
  price_member { 10 }
  price_regular { 20 }
  application_opening_at { Time.zone.yesterday }
  application_closing_at { Time.zone.tomorrow }
  before_create do |event|
    event.dates.build(start_at: 1.week.from_now) if event.dates.empty?
  end
end

Fabricator(:sac_event_kind, from: :event_kind) do
  kind_category_id { ActiveRecord::FixtureSet.identify(:ski_course) }
  short_name { Faker::Lorem.words.join }
  level_id { ActiveRecord::FixtureSet.identify(:ek) }
  cost_center_id { ActiveRecord::FixtureSet.identify(:tour) }
  cost_unit_id { ActiveRecord::FixtureSet.identify(:ski) }
end

Fabricator(:sac_event_kind_category, from: :event_kind_category) do
  cost_center_id { ActiveRecord::FixtureSet.identify(:tour) }
  cost_unit_id { ActiveRecord::FixtureSet.identify(:ski) }
end

Fabricator(:sac_tour, from: :event, class_name: :"Event::Tour") do
  groups { [Group.all_types.detect { |t| t.event_types.include?(Event::Tour) }.first] }
end
