# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::SurveyDispatchScheduleJob do
  let(:course) { events(:top_course) }

  subject(:job) { described_class.new }

  before do
    course.update!(survey_hero_survey_key: "5367281", survey_hero_collector_key: "8294016")
    course.update_column(:state, :ready)
  end

  def dispatch_jobs
    Delayed::Job.where("handler LIKE '%Event::SurveyDispatchJob%'").order(:run_at)
  end

  def scheduled_course_ids
    dispatch_jobs.map { |job| job.payload_object.parameters[:course_id] }
  end

  def fabricate_other_course
    Fabricate(:sac_open_course, groups: [groups(:root)],
      survey_hero_survey_key: "1", survey_hero_collector_key: "2",
      dates: [Event::Date.new(start_at: Time.zone.local(2023, 4, 10, 9))]).tap do |other|
      other.update_column(:state, :closed)
    end
  end

  it "reschedules for tomorrow at 08:00" do
    travel_to(Time.zone.local(2023, 4, 10, 8)) { job.perform }

    next_job = Delayed::Job.find_by("handler LIKE '%SurveyDispatchScheduleJob%'")
    expect(next_job.run_at).to eq Time.zone.local(2023, 4, 11, 8)
  end

  context "on last course day" do
    around { |example| travel_to(Time.zone.local(2023, 4, 10, 8)) { example.run } }

    it "schedules dispatch job for course" do
      job.perform

      expect(scheduled_course_ids).to eq [course.id]
    end

    it "schedules dispatch job in closed state" do
      course.update_column(:state, :closed)

      job.perform

      expect(scheduled_course_ids).to eq [course.id]
    end

    it "does not schedule dispatch job in state not allowing survey" do
      course.update_column(:state, :application_open)

      job.perform

      expect(scheduled_course_ids).to be_empty
    end

    it "does not schedule dispatch job with auto send disabled" do
      course.update_columns(survey_auto_send: false)

      job.perform

      expect(scheduled_course_ids).to be_empty
    end

    it "does not schedule dispatch job without survey key" do
      course.update!(survey_hero_survey_key: "")

      job.perform

      expect(scheduled_course_ids).to be_empty
    end

    it "does not schedule dispatch job with existing survey link" do
      course.update_column(:link_survey, "https://example.com/survey")

      job.perform

      expect(scheduled_course_ids).to be_empty
    end

    it "spaces dispatch jobs because of api rate limit" do
      other = fabricate_other_course

      job.perform

      expect(scheduled_course_ids).to match_array [course.id, other.id]
      expect(dispatch_jobs.map(&:run_at))
        .to eq [Time.zone.local(2023, 4, 10, 8), Time.zone.local(2023, 4, 10, 8, 0, 1)]
    end
  end

  it "does not schedule dispatch job before last course day" do
    travel_to(Time.zone.local(2023, 4, 9, 8)) { job.perform }

    expect(scheduled_course_ids).to be_empty
  end

  it "schedules dispatch job 7 days after last course day" do
    travel_to(Time.zone.local(2023, 4, 17, 8)) { job.perform }

    expect(scheduled_course_ids).to eq [course.id]
  end

  it "does not schedule dispatch job 8 days after last course day" do
    travel_to(Time.zone.local(2023, 4, 18, 8)) { job.perform }

    expect(scheduled_course_ids).to be_empty
  end

  it "uses start of last date as course end when it has no finish" do
    event_dates(:top_course_second).update!(finish_at: nil)

    travel_to(Time.zone.local(2023, 4, 3, 8)) { job.perform }

    expect(scheduled_course_ids).to eq [course.id]
  end
end
