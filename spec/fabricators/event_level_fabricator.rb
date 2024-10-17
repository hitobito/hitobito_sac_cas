# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

Fabricator(:event_level, class_name: "Event::Level") do
  label { Faker::Lorem.words.join(" ") }
  code { Faker::Number.between(from: 1, to: 1000) }
  difficulty { Faker::Number.between(from: 1, to: 1000) }
end
