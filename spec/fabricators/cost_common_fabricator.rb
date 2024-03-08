# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

Fabricator(:cost_unit) do
  code  { Faker::Lorem.characters(number: 10) }
  label { Faker::Lorem.words.join(" ") }
end

Fabricator(:cost_center) do
  code  { Faker::Lorem.characters(number: 10) }
  label { Faker::Lorem.words.join(" ") }
end
