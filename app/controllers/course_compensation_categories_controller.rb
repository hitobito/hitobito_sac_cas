# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class CourseCompensationCategoriesController < SimpleCrudController
  self.permitted_attrs = [:short_name,
    :kind,
    :description,
    :name_leader,
    :name_assistant_leader,
    :name_leader_aspirant,
    :name_assistant_leader_aspirant]
end
