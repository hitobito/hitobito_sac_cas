# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::SacCoursesExportJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:year]

  def initialize(user_id, filename, year, **)
    @year = year
    super(:xlsx, user_id, filename: filename, **)
  end

  def data
    Export::Tabular::Event::SacCourseFinances.xlsx(@year)
  end
end
