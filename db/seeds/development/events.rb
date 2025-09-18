# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require HitobitoSacCas::Wagon.root.join("db", "seeds", "development", "support", "sac_event_seeder")

srand(42)

seeder = SacEventSeeder.new

8.times do
  seeder.seed_event(Group.root_id, :course)
end
2.times do
  seeder.seed_event(Group.root_id, :course).update_column(:state, :assignment_closed)
end

Group.where(type: [Group::Sektion, Group::Ortsgruppe].map(&:sti_name)).find_each do |group|
  10.times do
    seeder.seed_event(group.id, :tour)
  end
  2.times do
    seeder.seed_event(group.id, :course)
  end
  2.times do
    seeder.seed_event(group.id, :base)
  end
end
