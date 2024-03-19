# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

Fabricator(:external_training) do
  person
  event_kind { Event::Kind.first }
  name { Faker::Lorem.words.join(" ") }
  provider { Faker::Lorem.words.join(" ") }
  start_at { 10.days.ago }
  finish_at { 5.days.ago }
  training_days { 5 }
end
