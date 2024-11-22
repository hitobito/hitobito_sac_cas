# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class CourseCompensationRatesController < SimpleCrudController
  self.permitted_attrs = [
    :valid_from,
    :valid_to,
    :rate_leader,
    :rate_assistant_leader,
    :course_compensation_category_id
  ]
end
