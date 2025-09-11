# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::TrainingDays::CoursesLoader
  CourseRecord = Data.define(:id, :to_s, :kind, :start_date, :qualification_date, :training_days)

  COURSE_COLUMNS = %w[
    events.id
    events.kind_id
    events.training_days
    event_participations.actual_days
  ].freeze

  def load
    load_courses(super) + load_external_trainings
  end

  def load_courses(scope)
    scope.select(COURSE_COLUMNS).map do |event|
      CourseRecord.new(
        event.id,
        event.to_s,
        event.kind,
        event.start_date,
        event.qualification_date,
        event.actual_days || event.training_days
      )
    end
  end

  def load_external_trainings
    fetch_external_trainings.map do |training|
      CourseRecord.new(
        training.id,
        training.to_s,
        training.event_kind,
        training.start_at,
        training.qualification_date,
        training.training_days
      )
    end
  end

  def fetch_external_trainings
    ExternalTraining.between(@start_date, @end_date)
      .where(person: @person_id)
      .includes(event_kind: {event_kind_qualification_kinds: :qualification_kind})
      .where(event_kind_qualification_kinds: {
        qualification_kind_id: @qualification_kind_ids,
        category: :prolongation,
        role: @role
      })
      .order("start_at DESC")
      .distinct
  end
end
