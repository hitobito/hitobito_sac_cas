# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::StateController do
  include ActiveJob::TestHelper

  before { sign_in(user) }

  describe "PUT#update" do
    context "course" do
      let(:group) { groups(:root) }

      context "as mitglied" do
        let(:user) { people(:mitglied) }
        let(:course) { Fabricate(:sac_course) }

        it "is unauthorized" do
          expect do
            put :update, params: {group_id: group.id, id: course.id, state: "application_open"}
          end.to raise_error(CanCan::AccessDenied)
        end
      end

      context "as admin" do
        let(:course) { Fabricate(:sac_open_course) }
        let(:user) { people(:admin) }

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
            course.participations.create!([{person: people(:admin)}, {person: people(:mitglied)},
              {person: people(:familienmitglied)}])
            course.participations.first.roles.create!(type: Event::Course::Role::Leader)
            course.participations.second.roles.create!(type: Event::Course::Role::AssistantLeader)
            course.participations.third.roles.create!(type: Event::Course::Role::Participant)
            course.update!(state: :created)
          end

          it "does send email" do
            expect do
              put :update, params: {group_id: group.id, id: course.id, state: :application_open}
            end.to change { course.reload.state }.from("created").to("application_open")
              .and have_enqueued_mail(Event::CourseMailer, :published).twice
          end

          it "skips sending emails when told to do so" do
            expect do
              put :update,
                params: {group_id: group.id, id: course.id, state: :application_open,
                         skip_emails: true}
            end.to change { course.reload.state }.from("created").to("application_open")
              .and not_have_enqueued_mail
          end
        end
      end

      context "tour" do
        let(:group) { groups(:bluemlisalp) }
        let(:event) { events(:section_tour) }
        let(:user) { people(:tourenchef) }
        let(:komitee) { groups(:bluemlisalp_freigabekomitee) }

        before do
          Group::SektionsTourenUndKurse::TourenchefSommer.create!(
            group: groups(:bluemlisalp_touren_und_kurse),
            person: user,
            start_on: "2015-01-01"
          )
        end

        def create_approval(kind, approved: true)
          event.approvals.create!(
            freigabe_komitee: komitee,
            approval_kind: event_approval_kinds(kind),
            approved:
          )
        end

        context "approve" do
          it "updates state and creates self approval" do
            put :update, params: {group_id: group.id, id: event.id, state: "approved"}

            expect(event.reload.state).to eq("approved")
            expect(event.approvals.count).to eq(1)
            expect(event.approvals.first.approved).to eq(true)
            expect(event.approvals.first.creator).to eq(user)
          end

          it "updates state, clears existing approvals and creates self approval" do
            create_approval(:professional)
            create_approval(:security, approved: false)
            event.update!(state: :draft)

            put :update, params: {group_id: group.id, id: event.id, state: "approved"}

            expect(event.reload.state).to eq("approved")
            expect(event.approvals.count).to eq(1)
            expect(event.approvals.first.approved).to eq(true)
            expect(event.approvals.first.creator).to eq(user)
          end
        end

        context "review" do
          before { event.update!(state: :draft) }

          it "destroys existing approvals" do
            create_approval(:professional)
            create_approval(:security, approved: false)

            put :update, params: {group_id: group.id, id: event.id, state: "review", button: "destroy"}

            expect(event.reload.state).to eq("review")
            expect(event.approvals.count).to eq(0)
          end

          it "keeps existing approvals" do
            create_approval(:professional)
            create_approval(:security, approved: false)

            put :update, params: {group_id: group.id, id: event.id, state: "review", button: "keep"}

            expect(event.reload.state).to eq("review")
            expect(event.approvals.count).to eq(2)
          end
        end
      end
    end
  end
end
