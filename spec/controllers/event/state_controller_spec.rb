# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::StateController do
  include ActiveJob::TestHelper

  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:group) { groups(:root) }
  let(:course) { Fabricate(:sac_course) }

  describe "PUT#update" do
    context "as mitglied" do
      before { sign_in(mitglied) }

      it "is unauthorized" do
        expect do
          put :update, params: {group_id: group.id, id: course.id, state: "application_open"}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      let(:course) { Fabricate(:sac_open_course) }

      before { sign_in(admin) }

      it "updates state if state change is possible" do
        put :update, params: {group_id: group.id, id: course.id, state: "created"}

        course.reload

        expect(flash[:notice]).to eq("Status wurde auf Entwurf gesetzt.")

        expect(course.state).to eq("created")
        expect(response).to redirect_to(group_event_path(group, course))
      end

      it "does not update state if new state is not available" do
        expect(course).to_not receive(:state=)

        put :update, params: {group_id: group.id, id: course.id, state: "ready"}

        expect(course.state).to eq("application_open")
        expect(response).to redirect_to(group_event_path(group, course))
      end

      it "does not update state if step makes event invalid" do
        course = Fabricate(:sac_course)

        put :update, params: {group_id: group.id, id: course.id, state: "application_open"}

        course.reload

        expect(course.state).to eq("created")
        expect(response).to redirect_to(group_event_path(group, course))
      end

      describe "skipping emails" do
        before do
          course.participations.create!([{person: people(:admin)}, {person: people(:mitglied)}, {person: people(:familienmitglied)}])
          course.participations.first.roles.create!(type: Event::Course::Role::Leader)
          course.participations.second.roles.create!(type: Event::Course::Role::AssistantLeader)
          course.participations.third.roles.create!(type: Event::Course::Role::Participant)
          course.update!(state: :created)
        end

        it "does send email" do
          expect do
            put :update, params: {group_id: group.id, id: course.id, state: :application_open}
          end.to change { course.reload.state }.from("created").to("application_open")
            .and have_enqueued_mail(Event::PublishedMailer, :notice).twice
        end

        it "skips sending emails when told to do so" do
          expect do
            put :update, params: {group_id: group.id, id: course.id, state: :application_open, skip_emails: true}
          end.to change { course.reload.state }.from("created").to("application_open")
            .and not_have_enqueued_mail
        end
      end
    end
  end
end
