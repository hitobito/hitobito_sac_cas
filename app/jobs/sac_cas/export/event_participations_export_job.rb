module SacCas::Export::EventParticipationsExportJob
  def exporter
    Export::Tabular::Event::Participations::CourseDataList if course_data?
  end

  def course_data?
    @options[:course_data]
  end
end
