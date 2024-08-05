# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::LeaderReminderJob do
  subject(:job) { described_class.new }

  context "rescheduling" do
    it "reschedules for tomorrow at 5 minutes past midnight" do
      job.perform
      next_job = Delayed::Job.find_by("handler like '%LeaderReminderJob%'")
      expect(next_job.run_at).to eq Time.zone.tomorrow + 5.minutes
    end
  end

  context "with contact person" do
    let!(:course) do
      Fabricate(:sac_open_course, contact_id: people(:admin).id, dates: [
        Fabricate(:event_date, start_at: 8.weeks.from_now)
      ])
    end

    context "with one course language" do
      it "mails a reminder" do
        expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end
    end

    context "with multiple course languages" do
      before { course.update!(language: "de_fr") }

      it "mails a reminder in both languages" do
        expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(1)
        expect(ActionMailer::Base.deliveries.last.body.to_s).to include("Hallo", "-----", "Bonjour")
      end
    end

    context "with course languages that doesnt have customcontent" do
      before { course.update!(language: "it") }

      it "mails a reminder in the default language" do
        expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(1)
        expect(ActionMailer::Base.deliveries.last.body.to_s).to include("Hallo")
      end
    end

    context "with course admin email" do
      before { course.groups.first.update!(course_admin_email: "admin@example.com") }

      it "mails a bcc to the admin" do
        expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(1)
        expect(ActionMailer::Base.deliveries.last.bcc).to include("admin@example.com")
      end
    end
  end

  context "course starts next week" do
    let!(:course) do
      Fabricate(:sac_open_course, contact_id: people(:admin).id, dates: [
        Fabricate(:event_date, start_at: 1.week.from_now)
      ])
    end

    it "mails a reminder" do
      expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(1)
    end
  end

  context "without contact person" do
    let!(:course) do
      Fabricate(:sac_open_course, dates: [
        Fabricate(:event_date, start_at: 8.weeks.from_now)
      ])
    end

    it "doesnt mail a reminder" do
      expect { job.perform }.not_to change(ActionMailer::Base.deliveries, :count)
    end
  end

  context "course doesnt start next week or in 8 weeks" do
    subject(:course) do
      Fabricate(:sac_open_course, contact_id: people(:admin).id, dates: [
        Fabricate(:event_date, start_at: start_at)
      ])
    end

    context "starts in 7 weeks" do
      let(:start_at) { 7.weeks.from_now }

      it "doesnt mail a reminder" do
        course
        expect { job.perform }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context "starts in 9 weeks" do
      let(:start_at) { 9.weeks.from_now }

      it "doesnt mail a reminder" do
        course
        expect { job.perform }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end
end
