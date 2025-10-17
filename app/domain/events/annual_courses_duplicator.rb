# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Events::AnnualCoursesDuplicator
  def initialize(source_year, target_year)
    @source_year = source_year
    @target_year = target_year
  end

  def run
    Event::Course.transaction do
      courses_to_duplicate.find_each do |course|
        Events::AnnualCourseDuplicateBuilder
          .new(course, @target_year, @target_year - @source_year)
          .create!
      end
    end
  end

  private

  def courses_to_duplicate
    Event::Course.includes(:dates)
      .where("number LIKE ?", "#{@source_year}-%")
      .where(annual: true)
  end
end
