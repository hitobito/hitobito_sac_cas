# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Events::Courses::SurveyDispatcher do
  let(:course) { events(:top_course) }
  let(:client) { instance_double(Events::Courses::SurveyHero::Client) }
  let(:top_mitglied) { event_participations(:top_mitglied) }
  let(:top_familienmitglied) { event_participations(:top_familienmitglied) }

  subject(:dispatch) { described_class.new(course, client:).dispatch }

  before do
    course.update!(survey_hero_survey_key: "5367281", survey_hero_collector_key: "8294016")
    course.update_column(:state, :ready)
    allow(client).to receive(:copy_collector).and_return("https://www.umfrageonline.com/c/abc")
  end

  it "stores course link as survey link" do
    dispatch

    expect(course.reload.link_survey)
      .to start_with("https://www.umfrageonline.com/c/abc?course-id=10")
  end

  it "sends survey to participants" do
    expect { dispatch }
      .to have_enqueued_mail(Event::CourseParticipationMailer, :survey).with(top_mitglied)
      .and have_enqueued_mail(Event::CourseParticipationMailer, :survey).with(top_familienmitglied)
  end

  it "sends survey in closed state" do
    course.update_column(:state, :closed)

    expect { dispatch }.to have_enqueued_mail(Event::CourseParticipationMailer, :survey).twice
  end

  %w[unconfirmed applied rejected absent canceled annulled].each do |state|
    it "does not send survey to #{state} participant" do
      top_familienmitglied.update_columns(state:)

      expect { dispatch }
        .to have_enqueued_mail(Event::CourseParticipationMailer, :survey).once.with(top_mitglied)
    end
  end

  it "does not send survey to leader" do
    leader = Fabricate(:event_participation, event: course, participant: people(:admin))
    Fabricate(Event::Course::Role::Leader.name.to_sym, participation: leader)

    expect { dispatch }.to have_enqueued_mail(Event::CourseParticipationMailer, :survey).twice
  end

  context "does nothing" do
    after do
      expect(client).not_to have_received(:copy_collector)
    end

    it "without survey key" do
      course.update!(survey_hero_survey_key: nil)

      expect { dispatch }.not_to have_enqueued_mail
    end

    it "without collector key" do
      course.update!(survey_hero_collector_key: nil)

      expect { dispatch }.not_to have_enqueued_mail
    end

    it "with auto send disabled" do
      course.update_columns(survey_auto_send: false, link_survey: nil)

      expect { dispatch }.not_to have_enqueued_mail
    end

    it "with existing survey link" do
      course.update_column(:link_survey, "https://example.com/survey")

      expect { dispatch }.not_to have_enqueued_mail
      expect(course.reload.link_survey).to eq "https://example.com/survey"
    end

    it "in state not allowing survey" do
      course.update_column(:state, :application_open)

      expect { dispatch }.not_to have_enqueued_mail
    end
  end

  context "when survey link cannot be created" do
    before do
      allow(client).to receive(:copy_collector)
        .and_raise(Events::Courses::SurveyHero::Client::Error, "Collector 1 has no survey link")
    end

    it "logs error on course" do
      expect { dispatch }.to change { HitobitoLogEntry.count }.by(1)

      expect(HitobitoLogEntry.last).to have_attributes(
        level: "error",
        category: "kursumfragen",
        message: "Der Umfragelink konnte nicht erstellt werden",
        payload: "Collector 1 has no survey link",
        subject: course
      )
    end

    it "replaces error logged by previous dispatch" do
      described_class.new(course, client:).dispatch

      expect { dispatch }.not_to change { HitobitoLogEntry.count }
    end

    it "does not send survey" do
      expect { dispatch }.not_to have_enqueued_mail
      expect(course.reload.link_survey).to be_nil
    end
  end
end
