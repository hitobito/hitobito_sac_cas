# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

Fabricator(:course_compensation_rate) do
  course_compensation_category
  valid_from { 5.days.ago }
  valid_to { 10.days.from_now }
  rate_leader { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
  rate_assistant_leader { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
end
