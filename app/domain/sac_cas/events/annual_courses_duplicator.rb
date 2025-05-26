class Events::AnnualCoursesDuplicator
  def initialize(source_year, target_year)
    @source_year = source_year
    @target_year = target_year
  end

  def run
    Event::Course.transaction do
      courses_to_duplicate.find_each do |course|
        duplicate = AnnualCourseDuplicator.new(course, source_year, target_year)
        duplicate.save!
      end
    end
  end

  def courses_to_duplicate
    Event::Course.includes(:dates)
      .where("number LIKE '?-%'", @source_year)
      .where(annual: true)
  end
end
