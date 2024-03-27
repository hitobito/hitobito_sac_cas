# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module ExternalTrainings
  class Qualifier < Event::Qualifier
    ROLE = 'participant'.freeze

    private

    def issue_qualifications
      with_adjusted_qualifications do
        super
      end
    end

    def revoke_qualifications
      with_adjusted_qualifications do
        super
      end
    end

    def with_adjusted_qualifications
      destroy_later_qualifications
      yield
      create_later_qualifications
    end

    def create_later_qualifications
      sorted_later_events.each do |event|
        QualifyAction.new(person, event, qualification_kinds(event.kind)).run
        ProlongAction.new(person, event, prolongation_kinds(event.kind), role).run
      end
    end

    def destroy_later_qualifications
      @person.qualifications
        .where(qualification_kind: qualifying_and_prolonging_kinds)
        .where('qualified_at > ?', @event.qualification_date)
        .destroy_all
    end

    def sorted_later_events
      (courses_loader.load - [@event]).sort_by(&:qualification_date)
    end

    def courses_loader
      @courses_loader ||= Event::TrainingDays::CoursesLoader.new(
        @person.id,
        ROLE,
        qualifying_and_prolonging_kinds,
        @event.qualification_date,
        Time.zone.today
      )
    end

    def qualifying_and_prolonging_kinds
      qualification_kinds + prolongation_kinds
    end
  end
end
