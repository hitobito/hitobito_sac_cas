# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

Fabricator(:sac_course, from: :course) do
  kind_id { ActiveRecord::FixtureSet.identify(:ski_course) }
  number { sequence(:number) }
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
