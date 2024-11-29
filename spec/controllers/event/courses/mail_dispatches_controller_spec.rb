# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Courses::MailDispatchesController do
  include ActiveJob::TestHelper

  before do
    sign_in(user)
    # leader participations
    [Event::Course::Role::Leader, Event::Course::Role::AssistantLeader].map do |event_role|
      Fabricate(event_role.name.to_sym,
        participation: Fabricate(:event_participation, event: course), self_employed: true)
    end
    # active participants
    4.times do
      Fabricate(Event::Course::Role::Participant.sti_name,
        participation: Fabricate(:event_participation, event: course, active: true))
    end

    course.update_column(:state, :ready)
  end

  let(:course) do
    Fabricate(:sac_course, kind: event_kinds(:ski_course), link_survey: "bitte-bitte-umfrage-ausfüllen.ch", language: "de")
  end
  let(:group) { course.groups.first }

  describe "POST #create" do
    context "as member" do
      let(:user) { people(:mitglied) }

      it "unauthorized" do
        expect do
          post :create, params: {group_id: group, event_id: course, mail_type: :leader_reminder}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      let(:user) { people(:admin) }

      it "sends leader reminder emails only to leader roles" do
        expect do
          post :create, params: {group_id: group, event_id: course, mail_type: :leader_reminder}
        end.to have_enqueued_mail(Event::LeaderReminderMailer, :reminder).exactly(1).times
        expect(flash[:notice]).to eq("Es wurde eine E-Mail verschickt.")
      end

      [:created, :application_open, :application_paused, :application_closed, :assignment_closed, :closed, :canceled].each do |state|
        it "unauthorized leader reminder mail for state #{state}" do
          course.update_column(:state, state)
          expect do
            post :create, params: {group_id: group, event_id: course, mail_type: :leader_reminder}
          end.to raise_error(CanCan::AccessDenied)
        end
      end

      it "sends survey emails to every active participation" do
        expect do
          post :create, params: {group_id: group, event_id: course, mail_type: :survey}
        end.to have_enqueued_mail(Event::SurveyMailer, :survey).exactly(4).times
        expect(flash[:notice]).to eq("Es wurden 4 E-Mails verschickt.")
      end

      it "sends no survey emails when no survey link" do
        course.update_column(:link_survey, nil)
        expect do
          post :create, params: {group_id: group, event_id: course, mail_type: :survey}
        end.not_to have_enqueued_mail(Event::SurveyMailer, :survey)
        expect(flash[:alert]).to eq("Es wurden keine E-Mails versendet, da kein Umfrage Link erfasst wurde.")
      end

      [:created, :application_open, :application_paused, :application_closed, :assignment_closed, :canceled].each do |state|
        it "unauthorized survey mail for state #{state}" do
          course.update_column(:state, state)
          expect do
            post :create, params: {group_id: group, event_id: course, mail_type: :survey}
          end.to raise_error(CanCan::AccessDenied)
        end
      end
    end
  end
end
