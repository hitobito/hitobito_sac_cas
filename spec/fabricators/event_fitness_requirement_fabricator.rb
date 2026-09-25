# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

Fabricator(:event_fitness_requirement, class_name: "Event::FitnessRequirement") do
  short_label { sequence(:event_fitness_requirement_short_label) { |i| "F#{i}" } }
  label { sequence(:event_fitness_requirement_label) { |i| "#{Faker::Job.seniority} #{i}" } }
  description { Faker::Lorem.sentence }
end
