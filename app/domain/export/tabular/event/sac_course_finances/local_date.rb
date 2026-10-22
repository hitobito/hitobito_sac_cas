# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Tabular::Event::SacCourseFinances
  module LocalDate
    private

    def local_date(column)
      time_zone = ActiveRecord::Base.connection.quote(Time.zone.tzinfo.name)
      "DATE(#{column} AT TIME ZONE 'UTC' AT TIME ZONE #{time_zone})"
    end
  end
end
