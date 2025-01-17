# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::CloseApplicationsJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.new }

  context "rescheduling" do
    it "reschedules for tomorrow at 5 minutes past midnight" do
      job.perform
      next_job = Delayed::Job.find_by("handler like '%CloseApplicationsJob%'")
      expect(next_job.run_at).to eq Time.zone.tomorrow + 5.minutes
    end
  end

  context "application_open" do
    let(:course) { Fabricate(:sac_open_course) }

    before { course.groups.first.update!(course_admin_email: "admin@example.com") }

    it "updates course state when application_closing_at is in the past" do
      travel_to(course.application_closing_at + 1.day) do
        expect { job.perform }.to change { course.reload.state }.to("application_closed")
          .and have_enqueued_mail(Event::ApplicationClosedMailer, :notice)
      end
    end

    it "keeps course state when application_closing_at is today" do
      travel_to(course.application_closing_at) do
        expect { job.perform }.not_to change { course.reload.state }
      end
    end
  end

  context "application_paused" do
    let(:course) { Fabricate(:sac_open_course, state: :application_paused) }

    before { course.groups.first.update!(course_admin_email: "admin@example.com") }

    it "updates course state when application_closing_at is in the past" do
      travel_to(course.application_closing_at + 1.day) do
        expect { job.perform }.to change { course.reload.state }.to("application_closed")
          .and have_enqueued_mail(Event::ApplicationClosedMailer, :notice)
      end
    end

    it "keeps course state when application_closing_at is today" do
      travel_to(course.application_closing_at) do
        expect do
          expect { job.perform }.not_to change { course.reload.state }
        end.not_to have_enqueued_mail(Event::ApplicationClosedMailer, :notice)
      end
    end
  end
end
