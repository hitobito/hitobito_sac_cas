# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Migrations
  # A one-off job to prolong qualifications of certain course participants.
  # Implements https://saccas.atlassian.net/browse/HIT-1172
  class ProlongCourseQualificationsJob < BaseJob
    PARTICIPANT_ROLE = "participant"

    def perform
      people_with_qualifications.in_batches(of: 50) do |batch|
        quali_events = preload_quali_events(batch)
        batch.each do |person|
          prolong_qualifications(person, quali_events.fetch(person.id))
        end
      end
    end

    def people_with_qualifications  # public for debugging purposes
      Person
        .where(id: (course_people_ids + external_training_people_ids).uniq)
        .joins(:qualifications)
        .where(qualifications: {qualification_kind_id: qualification_kinds.map(&:id)})
        .distinct
    end

    private

    def prolong_qualifications(person, quali_events)
      # revoke potentially existing qualifications to avoid that
      # there will be duplicates
      revoke_existing_qualifications(person, quali_events)
      prolong_all_qualifications(person, quali_events)
    end

    def revoke_existing_qualifications(person, quali_events)
      quali_events.reverse_each do |event|
        Event::Qualifier::RevokeAction.new(person, event, qualification_kinds).run
      end
    end

    def prolong_all_qualifications(person, quali_events)
      quali_events.each do |event|
        Event::Qualifier::ProlongAction.new(person, event, qualification_kinds, PARTICIPANT_ROLE).run
        flag_participation_qualified(person, event) if event.is_a?(Event::Course)
      end
    end

    def flag_participation_qualified(person, event)
      Event::Participation
        .find_by(participant_id: person.id, participant_type: Person.sti_name, event_id: event.id)
        .update_column(:qualified, true)
    end

    def qualification_kinds
      # In the SAC configuration, it's always the same qualification kinds
      # that are about to be prolonged by this job.
      @qualification_kinds ||=
        event_kinds.first.qualification_kinds("prolongation", PARTICIPANT_ROLE)
    end

    def preload_quali_events(people)
      external_trainings = preload_external_trainings(people)
      courses = preload_courses(people)

      people.each_with_object({}) do |person, hash|
        hash[person.id] = (
          courses.fetch(person.id, []) +
          external_trainings.fetch(person.id, [])
        ).sort_by(&:qualification_date)
      end
    end

    def preload_external_trainings(people)
      external_trainings.where(person_id: people.map(&:id)).group_by(&:person_id)
    end

    def preload_courses(people)
      person_course_ids = fetch_person_course_ids(people)
      courses = Event::Course.where(id: person_course_ids.values.flatten.uniq).index_by(&:id)

      person_course_ids.transform_values do |course_ids|
        course_ids.map { |id| courses.fetch(id) }
      end
    end

    def fetch_person_course_ids(people)
      courses
        .where(event_participations: {participant_id: people.map(&:id), participant_type: Person.sti_name})
        .pluck("event_participations.event_id", "event_participations.participant_id")
        .each_with_object({}) do |(event_id, person_id), hash|
          hash[person_id] ||= []
          hash[person_id] << event_id
        end
    end

    def course_people_ids
      Person
        .joins(event_participations: :event)
        .merge(courses)
        .distinct
        .pluck(:id)
    end

    def external_training_people_ids
      Person
        .joins(:external_trainings)
        .merge(external_trainings)
        .distinct
        .pluck(:id)
    end

    def external_trainings
      ExternalTraining
        .where(finish_at: beginning_of_year..)
        .where(event_kind: event_kinds)
    end

    def courses
      Event::Course
        .joins(:dates, participations: :roles)
        .where(
          "(event_dates.finish_at IS NULL AND event_dates.start_at >= :date)" \
          " OR event_dates.finish_at >= :date", date: beginning_of_year
        ).where(kind: event_kinds)
        .where(event_participations: {state: "attended"})
        .where(event_roles: {type: Event::Course::Role::Participant.sti_name})
    end

    def beginning_of_year
      @beginning_of_year ||= Date.current.beginning_of_year
    end

    def event_kinds
      Event::Kind.where(short_name: event_kind_short_names)
    end

    def event_kind_short_names
      %w[
        S6530
        S6585
        S2590
        S2300
        S7090
        S5615
        S0510
        S5800
        S7105
        S1430
        S0250
        S5750
        S2070
        S0540
        S5300
        S2585
        S0750
        S2450
        S0140
        S0315
        S2040
        S2030
        S6510
        S2150
        S0520
        S5215
        S5780
        S2530
        S5650
        S0910
        S5695
        S6850
        S7020
        S6600
        S2565
        S5040
        S1420
        S5050
        S0700
        S5035
        S7015
        S5730
        S5235
        S1120
        S5610
        S0900
        S0310
        S2560
        S6500
        S2010
        S5680
        S5600
        S2455
        S5720
        S1140
        S0120
        S0920
        S7035
        S0365
        S0100
        S5850
        S0340
        S7040
        S7000
        S5760
        S7010
        S6480
        S5280
        S6800
        S5700
        S2540
        S5670
        S7100
        S7001
        S5260
        S5900
        S2100
        S6855
        S7060
        S0360
        S5640
        S6560
        S5270
        S5620
        S7030
        S5690
        S1320
        S2060
        S6845
        S6820
        S6595
        S5660
        S0370
        S7155
        S7045
        S0380
        S5220
        S5290
        S5020
        S5210
        S7085
        S6840
        S5740
        S2595
        S5230
        S6520
        S5245
        S7055
        S2310
        S5060
        S7065
        S0335
        S5032
        S7025
        S0500
        S5240
        S5275
        S0300
        S7050
        S6580
        S6750
        S0320
        S2050
        S7150
        S6810
        S2350
        S7095
        S7070
        S2500
        S2570
        S2575
        S2480
        S2580
        S7080
        S5745
        S4000
        S0390
        S5200
        S6700
        S1100
        S2400
        S6590
        S5250
        S6570
        S7005
        S5000
        S6610
        S6900
        S1460
        S6550
        S5630
      ]
    end
  end
end
