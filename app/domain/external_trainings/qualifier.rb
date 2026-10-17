# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module ExternalTrainings
  class Qualifier
    ROLE_KIND = "participant"

    def initialize(person, training)
      @person = person
      @training = training
    end

    def issue
      Qualification.transaction do
        with_adjusted_qualifications do
          issue_action(@training)
        end
      end
    end

    def revoke
      Qualification.transaction do
        with_adjusted_qualifications do
          Event::Qualifier::RevokeAction.new(@person, @training, ROLE_KIND).run
        end
      end
    end

    private

    def with_adjusted_qualifications
      destroy_later_qualifications
      yield
      create_later_qualifications
    end

    def create_later_qualifications
      sorted_later_events.each do |event|
        issue_action(event)
      end
    end

    def issue_action(event)
      Event::Qualifier::QualifyAction.new(@person, event, ROLE_KIND).run
      Event::Qualifier::ProlongAction.new(@person, event, ROLE_KIND).run
    end

    def destroy_later_qualifications
      @person.qualifications
        .where(qualification_kind: qualifying_and_prolonging_kinds)
        .where("qualified_at > ?", @training.qualification_date)
        .destroy_all
    end

    def sorted_later_events
      courses_loader
        .load
        .reject { |c| c.id == @training.id && c.qualification_date == @training.qualification_date }
        .sort_by(&:qualification_date)
    end

    def courses_loader
      @courses_loader ||= Event::TrainingDays::CoursesLoader.new(
        @person.id,
        ROLE_KIND,
        qualifying_and_prolonging_kinds,
        @training.qualification_date,
        Time.zone.today
      )
    end

    def qualifying_and_prolonging_kinds
      @training.kind.qualification_kinds(%w[qualification prolongation], ROLE_KIND)
    end
  end
end
