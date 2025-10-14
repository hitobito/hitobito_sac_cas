# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module SacCas::Event::Qualifier::StartAtCalculator
  def initialize(*)
    super
    @event = SacCas::Event::TrainingDays::CoursesLoader::CourseRecord.new(
      @event.id,
      @event.to_s,
      @event.kind,
      @event.start_date,
      @event.qualification_date,
      event_training_days
    )
  end

  def event_training_days
    if @event.is_a?(Event::Course)
      @event.participations.find_by(participant_id: @person.id,
        participant_type: Person.sti_name).actual_days || @event.training_days
    else
      @event.training_days
    end
  end
end
