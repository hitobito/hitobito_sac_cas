# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::SurveyJob do
  include ActiveJob::TestHelper

  let(:course) do
    Fabricate(:sac_open_course,
      link_survey: "https://example.com/survey",
      dates: [Fabricate(:event_date, start_at: 1.week.ago, finish_at: 3.days.ago)],
      participations: Fabricate.times(2, :event_participation, state: :attended))
  end

  subject(:job) { described_class.new }

  context "rescheduling" do
    it "reschedules for tomorrow at 5 minutes past midnight" do
      job.perform
      next_job = Delayed::Job.find_by("handler like '%Event::SurveyJob%'")
      expect(next_job.run_at).to eq Time.zone.tomorrow + 5.minutes
    end
  end

  context "with two attended participations" do
    before { course }

    it "sends an email to both participants" do
      expect { job.perform }.to have_enqueued_mail(Event::SurveyMailer, :survey).twice
    end
  end

  context "with one attended participation" do
    before { course.participations.last.update!(state: :assigned) }

    it "sends an email to the participant" do
      expect { job.perform }.to have_enqueued_mail(Event::SurveyMailer, :survey).once
    end
  end

  context "without link_survey" do
    before { course.update!(link_survey: nil) }

    it "doesn't send an email" do
      expect { job.perform }.not_to have_enqueued_mail(Event::SurveyMailer)
    end
  end

  context "not 3 days ago" do
    before { course.dates.reload.first.update!(finish_at: 4.days.ago) }

    it "doesn't send an email" do
      expect { job.perform }.not_to have_enqueued_mail(Event::SurveyMailer)
    end
  end

  context "3 days ago but different time" do
    before do
      travel_to Time.zone.local(2024, 10, 27, 2, 0, 0)
      course.dates.reload.first.update!(finish_at: 3.days.ago + 1.hours)
    end

    it "sends an email to the participant" do
      expect { job.perform }.to have_enqueued_mail(Event::SurveyMailer, :survey).twice
    end
  end
end
