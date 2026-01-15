# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

Fabricator(:event_trait, class_name: "Event::Trait") do
  label { Faker::Lorem.word }
  description { Faker::Lorem.sentence }
end
