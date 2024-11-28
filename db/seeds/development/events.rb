# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require HitobitoSacCas::Wagon.root.join("db", "seeds", "development", "support", "sac_event_seeder")

srand(42)

seeder = SacEventSeeder.new

8.times do
  seeder.seed_event(Group.root.id, :course)
end
2.times do
  seeder.seed_event(Group.root.id, :course).update_column(:state, :assignment_closed)
end
