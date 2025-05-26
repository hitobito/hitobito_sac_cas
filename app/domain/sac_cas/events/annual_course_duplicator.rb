class SacCas::Events::AnnualCourseDuplicator
  def initialize(source_course, source_year, target_year)
    @source_course = source_course
    @source_year = source_year
    @target_year = target_year
  end

  def build
    course = @source_course.dup

    course.state = :created
    course.number = determine_next_number(@source_course)

    @source_course.dates.each do |blueprint_date|
      date = course.dates.build(blueprint_date.attributes)

      date.start_at = determine_next_date(blueprint_date.start_at.to_date)
      date.finish_at = determine_next_date(blueprint_date.finish_at&.to_date)
    end

    course.application_opening_at = determine_next_date(@source_course.application_opening_at.to_date)
    course.application_closing_at = determine_next_date(@source_course.application_closing_at&.to_date)

    Event::Translation.where(event_id: @source_course.id).find_each do |source_translation|
      course.translations.build(source_translation.attributes.except("id", "event_id"))
    end

    course
  end

  def determine_next_date(original_date)
    return unless original_date

    original_week_number = original_date.cweek
    original_weekday_number = original_date.cwday

    Date.commercial(@target_year.to_i, original_week_number, original_weekday_number)
  end

  def determine_next_number(course)
    course.number.gsub("#{@source_year}-", "#{@target_year}-")
  end
end
