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

  context "with course leaders" do
    let!(:course) do
      Fabricate(:sac_open_course, dates: [Fabricate(:event_date, start_at: 8.weeks.from_now)])
    end

    before do
      course.participations.create!([{person: people(:admin)}, {person: people(:mitglied)}])
      course.participations.first.roles.create!(type: Event::Role::Leader)
      course.participations.last.roles.create!(type: Event::Role::AssistantLeader)
    end

    it "mails a reminder to the course leaders" do
      expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(2)
      expect(ActionMailer::Base.deliveries.second_to_last.to).to include(people(:admin).email)
      expect(last_email.to).to include(people(:mitglied).email)
    end

    context "with course admin email" do
      before { course.groups.first.update!(course_admin_email: "admin@example.com") }

      it "mails a bcc to the admin" do
        expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(2)
        expect(last_email.bcc).to include("admin@example.com")
      end
    end

    context "with a course that starts next week and a course that starts in 8 weeks" do
      let(:course_next_week) do
        Fabricate(:sac_open_course, dates: [Fabricate(:event_date, start_at: 1.week.from_now)])
      end

      before do
        course_next_week.participations.create!(person: people(:admin))
        course_next_week.participations.first.roles.create!(type: Event::Role::Leader)
      end

      it "mails a reminder for both" do
        expect { job.perform }.to change(ActionMailer::Base.deliveries, :count).by(3)

        expect(ActionMailer::Base.deliveries.third_to_last.body.to_s).to match(/findet nächste Woche/)
        expect(last_email.body.to_s).to match(/findet 6 Wochen/)
      end
    end
  end

  context "without course leader" do
    before do
      Fabricate(:sac_open_course, dates: [Fabricate(:event_date, start_at: 1.week.from_now)])
    end

    it "doesn't mail a reminder" do
      expect { job.perform }.not_to change(ActionMailer::Base.deliveries, :count)
    end
  end

  context "course doesn't start next week or in 8 weeks" do
    subject(:course) do
      course = Fabricate(:sac_open_course, dates: [Fabricate(:event_date, start_at: start_at)])
      course.participations.create!(person: people(:admin))
      course.participations.first.roles.create!(type: Event::Role::Leader)
    end

    context "starts in 7 weeks" do
      let(:start_at) { 7.weeks.from_now }

      it "doesn't mail a reminder" do
        course
        expect { job.perform }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context "starts in 9 weeks" do
      let(:start_at) { 9.weeks.from_now }

      it "doesn't mail a reminder" do
        course
        expect { job.perform }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end
end
