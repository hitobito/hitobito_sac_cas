# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Export::EventParticipationsExportJob
  def exporter
    return super unless course_data?

    Export::Tabular::Event::Participations::CourseDataList
  end

  def course_data?
    @options[:course_data]
  end
end
