# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Migrations
  # A one-off job to adjust qualifications records to the requirements
  # of hitobito. Specifically, recalculate all qualifications based on
  # the person' course records
  # Implements https://saccas.atlassian.net/browse/HIT-1176 (Variante 1)
  class RecalculateQualificationRecordsJob < BaseJob # rubocop:disable Metrics/ClassLength
    PARTICIPATION_ROLE = "participant"

    attr_reader :changes

    def perform
      init_stats

      people_with_qualifications.find_each(batch_size: 50) do |person|
        courses = load_course_records(person)
        next if courses.empty?

        recalculate_qualifications(person, courses)
        yield if block_given?
      end
      @changes
    ensure
      changes_csv
    end

    # set ActiveRecord::Base.logger = nil before running
    def perform_with_progress
      total = people_with_qualifications.count
      current = 0

      perform do
        current += 1
        if (current % 10) == 0
          print "#{current} done. Progress: #{(current.to_f / total * 100).round(2)}% \r" # rubocop:disable Rails/Output
        end
      end
    end

    private

    def people_with_qualifications
      Person.joins(qualifications: :qualification_kind)
        .where(qualifications: {finish_at: Date.new(2018, 1, 1)..})
        .where.not(qualification_kinds: {validity: nil})
        .distinct
    end

    def load_course_records(person)
      (load_courses(person) + load_external_trainings(person)).sort_by(&:qualification_date)
    end

    def load_courses(person)
      Event::Course
        .includes(:dates, kind: {event_kind_qualification_kinds: :qualification_kind})
        .joins(:participations, kind: {event_kind_qualification_kinds: :qualification_kind})
        .where(event_participations: {qualified: true, participant: person})
        .where.not(qualification_kinds: {validity: nil})
        .where(event_kind_qualification_kinds: {role: PARTICIPATION_ROLE})
        .distinct
    end

    def load_external_trainings(person)
      ExternalTraining
        .where(person: person)
        .includes(event_kind: {event_kind_qualification_kinds: :qualification_kind})
        .where(event_kind_qualification_kinds: {role: PARTICIPATION_ROLE})
        .where.not(qualification_kinds: {validity: nil})
        .order("start_at DESC")
        .distinct
    end

    def recalculate_qualifications(person, courses)
      Person.transaction do
        record_quali_changes(person, courses) do
          adjust_old_qualifications(person, courses)
          reissue_qualifications(person, courses)
        end
      end
    end

    def adjust_old_qualifications(person, courses) # rubocop:disable Metrics/AbcSize
      qualis = person.qualifications.sort_by(&:start_at).group_by(&:qualification_kind)

      collect_first_course_dates(courses).each do |kind, first_course_date|
        next if !kind.validity || !qualis.key?(kind)

        first_quali_date = qualis[kind].first.start_at
        min_start_at = [first_quali_date, first_course_date].max
        max_finish_at = (min_start_at + kind.validity.years).end_of_year
        trim_qualifications(qualis[kind], min_start_at, max_finish_at)
      end
    end

    def trim_qualifications(existing, min_start_at, max_finish_at) # rubocop:disable Metrics/CyclomaticComplexity
      existing.each do |quali|
        if quali.start_at > min_start_at
          quali.destroy
        elsif quali.finish_at > max_finish_at
          exists = existing.any? do |q|
            q.id != quali.id && q.start_at == quali.start_at && q.finish_at == max_finish_at
          end
          if exists
            quali.destroy
          else
            quali.update!(finish_at: max_finish_at)
          end
        end
      end
    end

    def collect_first_course_dates(courses)
      courses.each_with_object({}) do |course, quali_kinds|
        course.kind.event_kind_qualification_kinds.each do |ekqk|
          quali_kinds[ekqk.qualification_kind] ||= course.qualification_date
        end
      end
    end

    def reissue_qualifications(person, courses)
      courses.each do |course|
        begin
          Event::Qualifier::QualifyAction.new(person, course,
            course_quali_kinds(course, "qualification")).run
        rescue ActiveRecord::RecordInvalid => e
          # ignore error if quali already exists
          raise e unless e.record.errors.details.dig(:qualification_kind_id, 0, :error) == :taken
        end
        Event::Qualifier::ProlongAction.new(person, course,
          course_quali_kinds(course, "prolongation"), PARTICIPATION_ROLE).run
      end
    end

    def course_quali_kinds(course, category)
      course.kind.qualification_kinds(category, PARTICIPATION_ROLE).where.not(validity: nil)
    end

    def record_quali_changes(person, courses)
      before = quali_records(person)
      yield
      after = quali_records(person)

      kind_courses = courses_by_quali_kind(courses)
      quali_kinds = before.keys + after.keys
      @changes[person.id] = quali_kinds.uniq.sort.index_with do |kind|
        {before: before[kind], after: after[kind], courses: kind_courses[kind]}
      end
      if after == before
        PaperTrail::Version.where(main: person, mutation_id:).destroy_all
      end
    end

    def quali_records(person)
      Qualification
        .where(person: person)
        .where.not(qualification_kind: {validity: nil})
        .includes(qualification_kind: :translations)
        .order(:start_at)
        .each_with_object(list_hash) do |q, h|
        h[q.qualification_kind.to_s] << [q.start_at, q.finish_at]
      end
    end

    def courses_by_quali_kind(courses)
      courses.each_with_object(list_hash) do |course, quali_kinds|
        course.kind.event_kind_qualification_kinds.each do |ekqk|
          quali_kinds[ekqk.qualification_kind.to_s] <<
            [course.qualification_date, course.training_days]
        end
      end
    end

    def list_hash
      Hash.new { |h, k| h[k] = [] }
    end

    def today
      @today ||= Date.current
    end

    def first_start_on
      @first_start_on ||= Date.new(2000, 1, 1)
    end

    def mutation_id
      @mutation_id ||= SecureRandom.uuid
    end

    def init_stats
      @changes = {}
      PaperTrail.request.whodunnit = "Recalculate Qualification Records Job"
      PaperTrail.request.controller_info = {mutation_id:}
    end

    def changes_csv
      csv = CSV.generate do |csv|
        csv << %w[person_id quali_kind before after trainings finish_before finish_after years_diff
          change_type changed]
        @changes.each do |id, quali_kinds|
          quali_kinds.each do |quali_kind, timespans|
            csv << csv_row(id, quali_kind, timespans)
          end
        end
      end
      File.write("quali_changes_#{mutation_id}.csv", csv)
    end

    def csv_row(id, quali_kind, timespans)
      finish_before, finish_after = finish_years(timespans)

      [
        id,
        quali_kind,
        timespans[:before].map { |s, f| "#{s} - #{f}" }.join("\n"),
        timespans[:after].map { |s, f| "#{s} - #{f}" }.join("\n"),
        timespans[:courses].map { |q, d| "#{q} (#{d})" }.join("\n"),
        finish_before,
        finish_after,
        (finish_before && finish_after) ? finish_after - finish_before : nil,
        change_type(finish_before, finish_after),
        timespans[:before] != timespans[:after]
      ]
    end

    def finish_years(timespans)
      [:before, :after].map { |type| timespans[type].map(&:last).max&.year }
    end

    def change_type(finish_before, finish_after) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      return unless finish_before && finish_after

      if finish_before >= today.year && finish_after < today.year - 4
        "bisher gültig, neu abgelaufen"
      elsif finish_before >= today.year && finish_after < today.year
        "bisher gültig, neu sistiert"
      elsif finish_before >= today.year
        "weiterhin gueltig"
      elsif finish_before >= today.year - 4 && finish_after < today.year - 4
        "bisher sistiert, neu abgelaufen"
      elsif finish_before >= today.year - 4 && finish_after < today.year
        "weiterhin sistiert"
      elsif finish_before >= today.year - 4
        "bisher sistiert, neu gültig"
      elsif finish_before < today.year - 4 && finish_after < today.year - 4
        "weiterhin abgelaufen"
      elsif finish_before < today.year - 4 && finish_after < today.year
        "bisher abgelaufen, neu sistiert"
      elsif finish_before < today.year - 4
        "bisher abgelaufen, neu gültig"
      end
    end
  end
end
