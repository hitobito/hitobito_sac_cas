# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Participations::MailDispatchesController do
  include ActiveJob::TestHelper

  let(:course) do
    Fabricate(:sac_course, kind: event_kinds(:ski_course),
      link_survey: "bitte-bitte-umfrage-ausfüllen.ch", language: "de")
  end
  let(:participation) do
    Event::Participation.create!(event: course, person: people(:mitglied))
  end
  let(:group) { course.groups.first }

  before { sign_in(user) }

  describe "POST #create" do
    context "as member" do
      let(:user) { people(:mitglied) }

      it "unauthorized" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :leader_reminder}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      let(:user) { people(:admin) }

      it "raises if trying to send participant email to leader" do
        Event::Course::Role::Leader.create!(participation: participation)
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_participation_canceled}
        end.to raise_error("Invalid mail type")
      end

      it "raises if trying to send leader email to participant" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_published_notice}
        end.to raise_error("Invalid mail type")
      end

      it "sends participation canceled email" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_participation_canceled}
        end.to have_enqueued_mail(Event::ParticipationCanceledMailer,
          :confirmation).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends canceled no leader email" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_canceled_no_leader}
        end.to have_enqueued_mail(Event::CanceledMailer, :no_leader).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends canceled minimum participants email" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_canceled_minimum_participants}
        end.to have_enqueued_mail(Event::CanceledMailer, :minimum_participants).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends canceled weather email" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_canceled_weather}
        end.to have_enqueued_mail(Event::CanceledMailer, :weather).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends participation summon email" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_participation_summon}
        end.to have_enqueued_mail(Event::ParticipationMailer, :summon).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends application confirmation assigned email" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :course_application_confirmation_assigned}
        end.to have_enqueued_mail(Event::ApplicationConfirmationMailer, :confirmation).with(
          participation, "course_application_confirmation_assigned"
        ).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends participation reject rejected email" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_participation_reject_rejected}
        end.to have_enqueued_mail(Event::ParticipationMailer, :reject_rejected).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends participation reject applied email" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_participation_reject_applied}
        end.to have_enqueued_mail(Event::ParticipationMailer, :reject_applied).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends survey email" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_survey}
        end.to have_enqueued_mail(Event::SurveyMailer, :survey).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends application confirmation unconfirmed email" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :course_application_confirmation_unconfirmed}
        end.to have_enqueued_mail(Event::ApplicationConfirmationMailer, :confirmation).with(
          participation, "course_application_confirmation_unconfirmed"
        ).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends application confirmation applied email" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :course_application_confirmation_applied}
        end.to have_enqueued_mail(Event::ApplicationConfirmationMailer, :confirmation).with(
          participation, "course_application_confirmation_applied"
        ).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends participation reminder email" do
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_participant_reminder}
        end.to have_enqueued_mail(Event::ParticipantReminderMailer,
          :reminder).with(participation).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends application published notice email" do
        Event::Course::Role::Leader.create!(participation: participation)
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_published_notice}
        end.to have_enqueued_mail(Event::PublishedMailer, :notice).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends leader reminder next week email" do
        Event::Course::Role::Leader.create!(participation: participation)
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_leader_reminder_next_week}
        end.to have_enqueued_mail(Event::LeaderReminderMailer, :reminder).with(participation,
          "event_leader_reminder_next_week").exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      it "sends leader reminder 8 weeks email" do
        Event::Course::Role::Leader.create!(participation: participation)
        expect do
          post :create,
            params: {group_id: group, event_id: course, participation_id: participation,
                     mail_type: :event_leader_reminder_8_weeks}
        end.to have_enqueued_mail(Event::LeaderReminderMailer, :reminder).with(participation,
          "event_leader_reminder_8_weeks")
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end
    end
  end
end
