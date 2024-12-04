# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::ParticipationsController do
  include ActiveJob::TestHelper

  before { sign_in(user) }

  let(:user) { people(:admin) }
  let(:group) { event.groups.first }
  let(:event) do
    Fabricate(:sac_open_course, groups: [groups(:root)], applications_cancelable: true).tap do |c|
      c.dates.first.update_columns(start_at: 1.day.from_now, finish_at: 1.week.from_now)
    end
  end
  let(:params) { {group_id: group.id, event_id: event.id} }

  describe "GET#index" do
    render_views
    subject(:dom) { Capybara::Node::Simple.new(response.body) }

    before do
      participation = Fabricate(:event_participation, event: event)
      Fabricate(Event::Role::Participant.sti_name, participation: participation)
    end

    it "renders state column" do
      get :index, params: params
      expect(dom).to have_css "th a", text: "Status"
      expect(dom).to have_css "td", text: "Bestätigt"
    end

    context "event without state" do
      let(:event) { events(:top_event) }

      it "hides state column" do
        get :index, params: params
        expect(dom).not_to have_css "th a", text: "Status"
        expect(dom).not_to have_css "td", text: "Bestätigt"
      end
    end
  end

  context "GET#new" do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    it "does not render aside for event" do
      event = Fabricate(:event)
      get :new, params: {group_id: event.groups.first.id, event_id: event.id}
      expect(dom).to have_css "#content > form"
      expect(dom).to have_css ".stepwizard-step", count: 2
      expect(dom).to have_css ".stepwizard-step.is-current", text: "Zusatzdaten"
      expect(dom).not_to have_css "aside"
    end

    it "does not render aside and wizard for someone else" do
      get :new, params: {group_id: group.id, event_id: event.id, for_someone_else: true}
      expect(dom).to have_css "#content > form"
      expect(dom).not_to have_css ".stepwizard-step", count: 2
      expect(dom).not_to have_css "aside"
    end

    it "renders aside for course" do
      get :new, params: {group_id: group.id, event_id: event.id}
      expect(dom).to have_css "main form"
      expect(dom).to have_css ".stepwizard-step", count: 3
      expect(dom).to have_css ".stepwizard-step.is-current", text: "Zusatzdaten"
      expect(dom).to have_css "aside.card", count: 2
    end

    it "doesn't render self_employed label" do
      get :new, params: {group_id: group.id, event_id: event.id}
      expect(dom).not_to have_field "Selbständig erwerbend"
    end
  end

  context "GET#show" do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }
    let(:participation) { Fabricate(:event_participation, event: event) }
    let(:params) { {group_id: group.id, event_id: event.id, id: participation.id} }

    it "includes cancel_statement field in cancel popover" do
      Fabricate(:event_application, participation: participation, priority_1: event,
        priority_2: event)
      get :show, params: params
      button = dom.find_button "Abmelden"
      content = Capybara::Node::Simple.new(button["data-bs-content"])
      expect(content).to have_field "Begründung"
      cancel_statement = content.find_field "Begründung"
      expect(cancel_statement["required"]).to eq "required"
    end

    it "includes cancel_statement on show page" do
      participation.update_columns(cancel_statement: "maybe next time", state: :canceled)

      get :show, params: params
      expect(dom).to have_css "dt", text: "Begründung"
      expect(dom).to have_css "dl", text: "maybe next time"
    end
  end

  context "POST#create" do
    render_views
    let(:user) { people(:mitglied) }
    let(:dom) { Capybara::Node::Simple.new(response.body) }
    let(:participation_id) { assigns(:participation).id }
    let(:participation_path) { group_event_participation_path(id: participation_id) }
    let(:mitglieder) { groups(:bluemlisalp_mitglieder) }
    let(:newsletter) { MailingList.find(Group.root.sac_newsletter_mailing_list_id) }

    context "event" do
      let(:event) { Fabricate(:event) }

      it "redirects to participation path" do
        expect do
          post :create, params: {group_id: group.id, event_id: event.id}
          expect(response).to redirect_to(participation_path)
        end.to change { Event::Participation.count }.by(1)
      end
    end

    it "redirects to participation path" do
      expect do
        post :create,
          params: {
            group_id: group.id,
            event_id: event.id,
            step: "summary",
            event_participation: {terms_and_conditions: "1", adult_consent: "1", newsletter: "1"}
          }
        expect(response).to redirect_to(participation_path)
      end.to change { Event::Participation.count }.by(1)
    end

    it "checks conditions for root courses" do
      expect do
        post :create, params: {group_id: group.id, event_id: event.id, step: "summary", event_participation: {newsletter: "0"}}
        expect(response).to render_template("new")
        expect(dom).to have_css "#error_explanation", text: "AGB muss akzeptiert werden"
      end.not_to change { Event::Participation.count }
      expect(newsletter.subscribed?(user)).to be_falsey
    end

    it "does not check conditions for non root courses" do
      event.groups = [groups(:bluemlisalp)]
      event.update!(globally_visible: true)
      expect do
        post :create, params: {group_id: groups(:bluemlisalp).id, event_id: event.id, step: "summary"}
        expect(response).to redirect_to(participation_path)
      end.to change { Event::Participation.count }.by(1)
    end

    context "newsletter" do
      it "is defined and user is subscribed by default" do
        expect(Group.root.sac_newsletter_mailing_list_id).to be_present
        expect(MailingList.where(id: Group.root.sac_newsletter_mailing_list_id)).to be_exist
        expect(newsletter.subscribed?(user)).to be_falsey
      end

      context "subscribed" do
        before { newsletter.subscriptions.create!(subscriber: user) }

        it "does nothing if newsletter is true" do
          expect do
            post :create,
              params: {
                group_id: group.id,
                event_id: event.id,
                step: "summary",
                event_participation: {terms_and_conditions: "1", adult_consent: "1", newsletter: "1"}
              }
            expect(response).to redirect_to(participation_path)
          end.to change { Event::Participation.count }.by(1)
          expect(newsletter.subscribed?(user)).to be_truthy
        end

        it "unsubscribe from sac mailing list" do
          expect do
            post :create,
              params: {
                group_id: group.id,
                event_id: event.id,
                step: "summary",
                event_participation: {terms_and_conditions: "1", adult_consent: "1", newsletter: "0"}
              }
            expect(response).to redirect_to(participation_path)
          end.to change { Event::Participation.count }.by(1)
          expect(newsletter.subscribed?(user)).to be_falsey
        end
      end

      context "unsubscribed" do
        it "subscribes to sac mailing list" do
          expect do
            post :create,
              params: {
                group_id: group.id,
                event_id: event.id,
                step: "summary",
                event_participation: {terms_and_conditions: "1", adult_consent: "1", newsletter: "1"}
              }
            expect(response).to redirect_to(participation_path)
          end.to change { Event::Participation.count }.by(1)
          expect(newsletter.subscribed?(user)).to be_truthy
        end

        it "does nothing if newsletter is false" do
          expect do
            post :create,
              params: {
                group_id: group.id,
                event_id: event.id,
                step: "summary",
                event_participation: {terms_and_conditions: "1", adult_consent: "1", newsletter: "0"}
              }
            expect(response).to redirect_to(participation_path)
          end.to change { Event::Participation.count }.by(1)
          expect(newsletter.subscribed?(user)).to be_falsey
        end
      end
    end

    context "not subsidizable" do
      let(:user) { people(:admin) }

      it "renders summary after answers" do
        post :create, params: params.merge(step: "answers")
        expect(response).to render_template("new")
        expect(dom).to have_css ".stepwizard-step", count: 3
        expect(dom).to have_css ".stepwizard-step.is-current", text: "Zusammenfassung"
      end

      it "goes back to answers from summary" do
        post :create, params: params.merge(step: "summary", back: "true")
        expect(response).to render_template("new")
        expect(dom).to have_css ".stepwizard-step", count: 3
        expect(dom).to have_css ".stepwizard-step.is-current", text: "Zusatzdaten"
      end

      it "redirects to contact data when going back from answers" do
        post :create, params: params.merge(step: "answers", back: "true")
        expect(response).to redirect_to(contact_data_group_event_participations_path(group, event))
      end
    end

    context "subsidizable" do
      before { event.update!(price_subsidized: 10) }

      it "renders subsidy after answers" do
        post :create, params: params.merge(step: "answers")
        expect(response).to render_template("new")
        expect(dom).to have_css ".stepwizard-step", count: 4
        expect(dom).to have_css ".stepwizard-step.is-current", text: "Subventionsbeitrag"
      end

      it "goes back to subsidy from summary" do
        post :create, params: params.merge(step: "summary", back: true)
        expect(response).to render_template("new")
        expect(dom).to have_css ".stepwizard-step", count: 4
        expect(dom).to have_css ".stepwizard-step.is-current", text: "Subventionsbeitrag"
      end
    end

    describe "default states" do
      let(:mitglied) { people(:mitglied) }
      let(:participation) { assigns(:participation) }

      context "without automatic_assignment" do
        before { event.update!(automatic_assignment: false) }

        it "sets participation state to unconfirmed" do
          post :create, params: params.merge(event_participation: {person_id: user.id})
          expect(participation.state).to eq "unconfirmed"
        end

        it "sets participation state to applied if no places are available" do
          event.update!(maximum_participants: 2, participant_count: 2)
          post :create, params: params.merge(event_participation: {person_id: user.id})
          expect(participation.state).to eq "applied"
        end
      end

      context "with automatic_assignment" do
        before { event.update!(automatic_assignment: true) }

        it "sets participation state to assigned" do
          post :create, params: params.merge(event_participation: {person_id: user.id})
          expect(participation.state).to eq "assigned"
        end

        it "sets participation state to applied if no places are available" do
          event.update!(maximum_participants: 2, participant_count: 2)

          post :create, params: params.merge(event_participation: {person_id: user.id})
          expect(participation.state).to eq "applied"
        end
      end
    end
  end

  context "state changes" do
    let(:participation) { Fabricate(:event_participation, event: event) }
    let(:params) { {group_id: group.id, event_id: event.id, id: participation.id} }

    it "PUT#summon sets participation active and state to summoned" do
      expect { put :summon, params: params }
        .not_to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"), :count)
      expect(participation.reload.active).to be true
      expect(participation.state).to eq "summoned"
      expect(flash[:notice]).to match(/wurde aufgeboten/)
    end

    it "PUT#summon enqueues invoice if participation price is set" do
      participation.update!(price: 10)
      expect { put :summon, params: params }
        .to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"), :count).by(1)
        .and change { participation.reload.state }.to("summoned")
    end

    it "PUT#summon doesn't enqueue same invoice twice" do
      ExternalInvoice::CourseParticipation.create!(person: participation.person, total: 10, link: participation)
      participation.update!(price: 10)

      expect(ExternalInvoice::CourseParticipation).not_to receive(:invoice!)
      expect { put :summon, params: params }
        .not_to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"), :count)
    end

    it "PUT#cancel sets statement and default canceled_at" do
      freeze_time
      put :cancel, params: params.merge({event_participation: {cancel_statement: "next time!"}})
      expect(participation.reload.state).to eq "canceled"
      expect(participation.canceled_at).to eq Time.zone.today
      expect(participation.cancel_statement).to eq "next time!"
    end

    it "PUT#cancel can override canceled_at" do
      freeze_time
      put :cancel, params: params.merge({event_participation: {canceled_at: 1.day.ago}})
      expect(participation.reload.state).to eq "canceled"
      expect(participation.canceled_at).to eq 1.day.ago.to_date
      expect(participation.cancel_statement).to be_nil
    end

    it "PUT#cancel cannot override canceled_at when canceling own participation" do
      freeze_time
      participation.update!(person: people(:admin))
      put :cancel, params: params.merge({event_participation: {canceled_at: 1.day.ago}})
      expect(participation.reload.state).to eq "canceled"
      expect(participation.canceled_at).to eq Time.zone.today
      expect(participation.cancel_statement).to be_nil
    end

    it "PUT#cancel fails if participation cancels but not cancelable by participant" do
      freeze_time
      event.update_columns(applications_cancelable: false)
      participation.update!(person: people(:admin))
      put :cancel, params: params.merge({event_participation: {canceled_at: 1.day.ago}})
      expect(participation.reload.state).to eq "assigned"
      expect(flash[:alert]).to eq ["ist nicht gültig"]
    end

    it "PUT#cancel creates course annulation invoice and enqueues cancel invoice job if person has invoice" do
      invoice = participation.person.external_invoices.create!(type: ExternalInvoice::SacMembership.sti_name, link: participation)
      participation.update!(price: 10)
      freeze_time

      expect { put :cancel, params: params.merge({event_participation: {canceled_at: 1.day.ago}}) }
        .to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"), :count).by(1)
        .and change(Delayed::Job.where("handler LIKE '%CancelInvoiceJob%'"), :count).by(1)
        .and change { invoice.reload.state }.to("cancelled")
        .and change { participation.reload.state }.to("canceled")
        .and change { ExternalInvoice::CourseAnnulation.count }.by(1)

      invoice = ExternalInvoice::CourseAnnulation.find_by(link: participation, person: participation.person)
      expect(invoice).to be_present
      expect(invoice.issued_at).to eq(Date.current)
      expect(invoice.sent_at).to eq(Date.current)
      expect(invoice.state).to eq("draft")
      expect(invoice.year).to eq(event.dates.first.start_at.year)
    end
  end

  describe "PUT#update" do
    let(:participation) { Fabricate(:event_participation, event: event) }
    let(:participation_path) { group_event_participation_path(id: participation.id) }

    it "allows to edit actual_days with participations_full in event" do
      own_participation = Event::Participation.create!(event: event, person: user, application_id: -1)
      Event::Course::Role::Leader.create!(participation: own_participation)
      patch :update,
        params: {
          group_id: group.id,
          event_id: event.id,
          id: participation.id,
          event_participation: {actual_days: "2", person_id: participation.person.id}
        }
      expect(response).to redirect_to(participation_path)
      expect(participation.reload.actual_days).to eq(2)
    end

    it "does not allow to edit actual_days without participations_full in event" do
      patch :update,
        params: {
          group_id: group.id,
          event_id: event.id,
          id: participation.id,
          event_participation: {actual_days: 2}
        }
      expect(response).to redirect_to(participation_path)
      expect(participation.reload.actual_days).to be_nil
    end

    describe "#price_category" do
      before { participation.update!(price: 20, price_category: "price_regular") }

      it "updates price when changing price_category" do
        expect do
          put :update, params: {group_id: group.id, event_id: event.id, id: participation.id,
                                event_participation: {price_category: "price_member"}}
        end.to change { participation.reload.price }.from(20).to(10)
          .and change { participation.price_category }.from("price_regular").to("price_member")
      end

      it "updates price when event#price changed, even if price_category stays the same" do
        event.update!(price_regular: 30)
        expect do
          put :update, params: {group_id: group.id, event_id: event.id, id: participation.id,
                                event_participation: {price_category: "price_regular"}}
        end.to change { participation.reload.price }.from(20).to(30)
          .and not_change { participation.price_category }
      end

      it "doesn't update price when event#price changed if price_category should still use former price" do
        event.update!(price_regular: 30)
        expect do
          put :update, params: {group_id: group.id, event_id: event.id, id: participation.id,
                                event_participation: {price_category: "former"}}
        end.to not_change { participation.reload.price }
          .and not_change { participation.price_category }
      end
    end
  end
end
