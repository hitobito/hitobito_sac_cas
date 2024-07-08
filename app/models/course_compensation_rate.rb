# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class CourseCompensationRate < ApplicationRecord

  belongs_to :course_compensation_category

  validate :assert_category_uniqueness_during_validity_period

  def assert_category_uniqueness_during_validity_period
    scope = CourseCompensationRate.where(course_compensation_category: course_compensation_category)
    if scope.where(':valid_from BETWEEN valid_from AND valid_to OR :valid_to BETWEEN valid_from AND valid_to',
                   valid_from: valid_from, valid_to: valid_to).any?
      errors.add(:course_compensation_category, :uniqueness_during_validity_period)
    end
  end

end
