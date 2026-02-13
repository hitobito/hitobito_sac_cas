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
      participation = Fabricate(:event_participation, event: event, invoice_state: :draft)
      Fabricate(Event::Role::Participant.sti_name, participation: participation)
    end

    context "event state" do
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

      context "participation invoice_state" do
        it "renders invoice_state column with values" do
          TableDisplay.create!(person: user, selected: ["invoice_state"],
            table_model_class: Event::Participation.sti_name)

          get :index, params: params
          expect(dom).to have_css "th a", text: "Rechnung"
          expect(dom).to have_css "td", text: "Entwurf"
        end
      end
    end

    context "list pdf" do
      it "renders pdf" do
        expect_any_instance_of(Export::Pdf::Participations::ParticipantList).to receive(:render)
        get :index, params: params.merge(format: :pdf, list_kind: "for_participants")
        expect(@response.media_type).to eq("application/pdf")
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

    context "regular event" do
      let(:event) { Fabricate(:event) }

      it "redirects to participation path" do
        expect do
          post :create, params: {group_id: group.id, event_id: event.id}
          expect(response).to redirect_to(participation_path)
        end.to change { Event::Participation.count }.by(1)
      end
    end

    context "with automatic_assignment=true" do
      before { event.update!(automatic_assignment: true) }

      it "enqueues confirmation job" do
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
          .and change(Delayed::Job.where("handler like '%ParticipationConfirmationJob%'"),
            :count).by(1)
      end
    end

    context "with automatic_assignment=false" do
      before { event.update!(automatic_assignment: false) }

      it "enqueues confirmation job" do
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
          .and change(Delayed::Job.where("handler like '%ParticipationConfirmationJob%'"),
            :count).by(1)
      end
    end

    it "redirects to participation path" do
      event.update!(training_days: 1)
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
      expect(assigns(:participation).actual_days).to eq(1)
    end

    it "checks conditions for root courses" do
      expect do
        post :create,
          params: {group_id: group.id, event_id: event.id, step: "summary",
                   event_participation: {newsletter: "0"}}
        expect(response).to render_template("new")
        expect(dom).to have_css "#error_explanation", text: "AGB muss akzeptiert werden"
      end.not_to change { Event::Participation.count }
      expect(newsletter.subscribed?(user)).to be_falsey
    end

    it "does not check conditions for non root courses" do
      event.groups = [groups(:bluemlisalp)]
      event.update!(globally_visible: true)
      expect do
        post :create,
          params: {group_id: groups(:bluemlisalp).id, event_id: event.id, step: "summary"}
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
                event_participation: {terms_and_conditions: "1", adult_consent: "1",
                                      newsletter: "1"}
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
                event_participation: {terms_and_conditions: "1", adult_consent: "1",
                                      newsletter: "0"}
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
                event_participation: {terms_and_conditions: "1", adult_consent: "1",
                                      newsletter: "1"}
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
                event_participation: {terms_and_conditions: "1", adult_consent: "1",
                                      newsletter: "0"}
              }
            expect(response).to redirect_to(participation_path)
          end.to change { Event::Participation.count }.by(1)
          expect(newsletter.subscribed?(user)).to be_falsey
        end
      end
    end

    context "answers" do
      before do
        event.init_questions
        event.application_questions.find { |q| q.question == "AHV-Nummer?" }.disclosure = "required"
        event.save!
      end

      it "displays validation error if required answers are missing" do
        post :create, params: params.merge(
          step: "answers",
          event_participation: {answers_attributes: {
            "0" => {"question_id" => event.application_questions.first.id, "answer" => ""},
            "1" => {"question_id" => event.application_questions.second.id, "answer" => ""},
            "2" => {"question_id" => event.application_questions.third.id, "answer" => ""}
          }}
        )

        expect(response).to render_template("new")
        expect(dom).to have_css ".stepwizard-step.is-current", text: "Zusatzdaten"
        expect(dom).to have_text "Antwort muss ausgefüllt werden"
      end

      it "proceeds to next step if required answers are given" do
        post :create, params: params.merge(
          step: "answers",
          event_participation: {answers_attributes: {
            "0" => {"question_id" => event.application_questions.first.id,
                    "answer" => "756.1234.5678.97"},
            "1" => {"question_id" => event.application_questions.second.id, "answer" => "Henä"},
            "2" => {"question_id" => event.application_questions.third.id, "answer" => "Fränä"}
          }}
        )

        expect(response).to render_template("new")
        expect(dom).to have_css ".stepwizard-step.is-current", text: "Zusammenfassung"
      end

      context "as admin" do
        let(:user) { people(:admin) }

        it "saves participation even if required answers are empty" do
          expect do
            post :create, params: params.merge(
              event_participation: {
                person_id: people(:mitglied).id,
                for_someone_else: true,
                answers_attributes: {
                  "0" => {"question_id" => event.application_questions.first.id,
                          "answer" => "756.1234.5678.97"}
                }
              }
            )
          end.to change { Event::Participation.count }.by(1)
          expect(response).to redirect_to(participation_path)
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

    context "default states" do
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

    context "pricing" do
      before { event.update!(price_member: 30, price_regular: 50, price_subsidized: 10) }

      let(:participation) { assigns(:participation) }

      context "member" do
        let(:user) { people(:mitglied) }

        it "sets subsidized price if requested" do
          expect do
            post :create, params: params.merge(event_participation: {subsidy: true})
          end.to change { Event::Participation.count }.by(1)
          expect(participation.price).to eq 10
          expect(participation.price_category).to eq("price_subsidized")
        end

        it "sets member price if no subsidy requested" do
          expect do
            post :create, params: params
          end.to change { Event::Participation.count }.by(1)
          expect(participation.price).to eq 30
          expect(participation.price_category).to eq("price_member")
        end
      end

      context "non-member" do
        let(:user) { people(:abonnent) }

        it "sets regular price if subsidized price is not available" do
          expect do
            post :create, params: params.merge(event_participation: {subsidy: true})
          end.to change { Event::Participation.count }.by(1)
          expect(participation.price).to eq 50
          expect(participation.price_category).to eq("price_regular")
        end

        it "cannot set price or category itself" do
          expect do
            post :create,
              params: params.merge(event_participation: {price_category: "price_member", price: 1})
          end.to change { Event::Participation.count }.by(1)
          expect(participation.price).to eq 50
          expect(participation.price_category).to eq("price_regular")
        end
      end

      context "admin" do
        let(:user) { people(:admin) }

        it "set arbitrary category for someone else" do
          expect do
            post :create,
              params: params.merge(event_participation: {person_id: people(:abonnent).id,
                                                         price_category: "price_member"})
          end.to change { Event::Participation.count }.by(1)
          expect(participation.price).to eq 30
          expect(participation.price_category).to eq("price_member")
        end
      end
    end

    context "as layer_events_full" do
      let(:kommission_touren) { groups(:bluemlisalp_kommission_touren) }
      let(:user) {
        Group::SektionsKommissionTouren::Mitglied.create!(group: kommission_touren,
          person: Fabricate(:person)).person
      }
      let(:event) { events(:section_tour) }

      before do
        groups(:bluemlisalp).update!(require_person_add_requests: true)
        groups(:matterhorn).update!(require_person_add_requests: true)
      end

      it "creates participation for person in same layer" do
        person = people(:mitglied)
        expect do
          post :create, params: {
            group_id: group.id,
            event_id: event.id,
            event_participation: {person_id: person.id},
            event_role: {type: "Event::Tour::Role::Participant"}
          }
          expect(response).to redirect_to(participation_path)
        end.to change { Event::Participation.count }.by(1)
          .and change { Person::AddRequest::Event.count }.by(0)

        expect(assigns(:participation).person).to eq person
      end

      it "requests approval for person in other layer" do
        person = Group::SektionsMitglieder::Mitglied.create!(
          person: Fabricate(:person),
          group: groups(:matterhorn_mitglieder),
          start_on: 1.year.ago,
          end_on: Date.current.end_of_year
        ).person
        expect do
          post :create, params: {
            group_id: group.id,
            event_id: event.id,
            event_participation: {person_id: person.id},
            event_role: {type: "Event::Tour::Role::Participant"}
          }
          expect(response).to redirect_to(group_event_participations_path)
        end.to change { Event::Participation.count }.by(0)
          .and change { Person::AddRequest::Event.count }.by(1)
      end
    end
  end

  context "PUT #update" do
    let(:participation) { Fabricate(:event_participation, event: event) }
    let(:participation_path) { group_event_participation_path(id: participation.id) }

    it "can edit actual_days" do
      patch :update,
        params: {
          group_id: group.id,
          event_id: event.id,
          id: participation.id,
          event_participation: {actual_days: 2}
        }
      expect(response).to redirect_to(participation_path)
      expect(participation.reload.actual_days).to eq(2)
    end

    context "as any person" do
      let(:user) { participation.person }

      it "cannot edit own actual_days" do
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
    end

    context "as course leader" do
      let(:user) { people(:mitglied) }

      it "can edit actual_days" do
        own_participation = Event::Participation.create!(event: event, participant: user,
          application_id: -1)
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
    end

    context "#price_category" do
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

      it "clears price when removing price_category" do
        expect do
          put :update, params: {group_id: group.id, event_id: event.id, id: participation.id,
                                event_participation: {price_category: ""}}
        end.to change { participation.reload.price }.from(20).to(nil)
          .and change { participation.price_category }.from("price_regular").to(nil)
      end

      # rubocop:todo Layout/LineLength
      it "doesn't update price when event#price changed if price_category should still use former price" do
        # rubocop:enable Layout/LineLength
        event.update!(price_regular: 30)
        expect do
          put :update, params: {group_id: group.id, event_id: event.id, id: participation.id,
                                event_participation: {price_category: "former"}}
        end.to not_change { participation.reload.price }
          .and not_change { participation.price_category }
      end

      context "for user participation" do
        let(:user) { participation.person }

        it "can update answers, but not price" do
          event.update!(price_special: 12)
          put :update, params: {
            group_id: event.groups.first.id,
            event_id: event.id,
            id: participation.id,
            event_participation: {price_category: "price_special",
                                  additional_information: "Bla bla"}
          }
          expect(response).to redirect_to(participation_path)

          participation.reload
          expect(participation.price).to eq(20.0)
          expect(participation.price_category).to eq("price_regular")
          expect(participation.additional_information).to eq("Bla bla")
        end
      end
    end
  end

  context "state changes" do
    let(:participation) { Fabricate(:event_participation, event: event) }
    let!(:event_role) { Event::Course::Role::Participant.create!(participation: participation) }
    let(:params) { {group_id: group.id, event_id: event.id, id: participation.id} }

    context "PUT#summon" do
      it "sets participation active and state to summoned" do
        expect { put :summon, params: params }
          .not_to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"), :count)
        expect(participation.reload.active).to be true
        expect(participation.state).to eq "summoned"
        expect(flash[:notice]).to match(/wurde aufgeboten/)
      end

      it "enqueues invoice if participation price is set" do
        participation.update!(price: 10, price_category: :price_regular)
        expect { put :summon, params: params }
          .to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"), :count).by(1)
          .and change { participation.reload.state }.to("summoned")
      end

      it "doesn't enqueue same invoice twice" do
        ExternalInvoice::CourseParticipation.create!(person: participation.person, total: 10,
          link: participation)
        participation.update!(price: 10, price_category: :price_regular)

        expect(ExternalInvoice::CourseParticipation).not_to receive(:invoice!)
        expect { put :summon, params: params }
          .not_to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"), :count)
      end

      it "sends summon email when send_email is true" do
        expect { put :summon, params: params.merge(send_email: true) }
          .to have_enqueued_mail(Event::ParticipationMailer, :summon).once
      end

      it "does not send summon email when send_email is false" do
        expect { put :summon, params: params.merge(send_email: false) }
          .not_to have_enqueued_mail(Event::ParticipationMailer, :summon)
      end
    end

    context "reactivate" do
      before {
        participation.update!(state: :canceled, cancel_statement: "Keine Lust",
          canceled_at: Date.current)
      }

      it "PUT#reactivate sets participation to applied when maximum participants is reached" do
        allow_any_instance_of(Event).to receive(:maximum_participants_reached?).and_return(true)
        put :reactivate, params: params
        expect(participation.reload.state).to eq "applied"
        expect(participation.reload.cancel_statement).to be_nil
        expect(participation.reload.canceled_at).to be_nil
      end

      it "refreshes event participant_count" do
        event.refresh_participant_counts!
        expect do
          put :reactivate, params: params
        end.to change { event.reload.participant_count }.by(1)
      end

      # rubocop:todo Layout/LineLength
      it "PUT#reactivate sets particpation to assigned when maximum participants has not been reached" do
        # rubocop:enable Layout/LineLength
        put :reactivate, params: params
        expect(participation.reload.state).to eq "assigned"
        expect(participation.reload.cancel_statement).to be_nil
        expect(participation.reload.canceled_at).to be_nil
      end
    end

    context "PUT#cancel" do
      context "as participant" do
        let(:user) { participation.person }

        it "sets default canceled_at and statement" do
          freeze_time
          put :cancel,
            params: params.merge({event_participation: {canceled_at: 1.day.ago.to_date,
                                                        cancel_statement: "next time!"}})
          expect(participation.reload.state).to eq "canceled"
          expect(participation.canceled_at).to eq Time.zone.today
          expect(participation.cancel_statement).to eq("next time!")
        end

        it "fails if not cancelable by participant" do
          freeze_time
          event.update_columns(applications_cancelable: false)
          put :cancel, params: params
          expect(participation.reload.state).to eq "assigned"
          expect(flash[:alert]).to eq ["ist nicht gültig"]
        end

        it "always sends email" do
          expect { put :cancel, params: params }
            .to have_enqueued_mail(Event::ParticipationCanceledMailer, :confirmation).once
        end

        # rubocop:todo Layout/LineLength
        it "creates course annulation invoice and enqueues cancel invoice job if person has invoice" do
          # rubocop:enable Layout/LineLength
          invoice = participation.person.external_invoices.create!(
            type: ExternalInvoice::SacMembership.sti_name, link: participation
          )
          participation.update!(price: 10, price_category: :price_regular)
          freeze_time

          expect { put :cancel, params: params }
            .to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"), :count).by(1)
            .and change(Delayed::Job.where("handler LIKE '%CancelInvoiceJob%'"), :count).by(1)
            .and change { invoice.reload.state }.to("cancelled")
            .and change { participation.reload.state }.to("canceled")
            .and change { ExternalInvoice::CourseAnnulation.count }.by(1)

          invoice = ExternalInvoice::CourseAnnulation.find_by(link: participation,
            person: participation.person)
          expect(invoice).to be_present
          expect(invoice.issued_at).to eq(Date.current)
          expect(invoice.sent_at).to eq(Date.current)
          expect(invoice.state).to eq("draft")
          expect(invoice.year).to eq(event.dates.first.start_at.year)
        end

        it "does not create course annulation invoice when participation state is applied" do
          participation.update!(price: 10, price_category: :price_regular)
          participation.update_column(:state, :applied)

          expect do
            put :cancel, params: params
          end.not_to change { ExternalInvoice::CourseAnnulation.count }

          expect(participation.reload.state).to eq("canceled")
        end

        it "ignores option for custom price" do
          expect(ExternalInvoice::CourseAnnulation).to receive(:invoice!).with(participation)
          put :cancel, params: params.merge({invoice_option: "custom", custom_price: "5.0"})
        end

        context "for tour" do
          let(:event) do
            Fabricate(:sac_tour, groups: [groups(:bluemlisalp)],
              applications_cancelable: true).tap do |c|
              c.dates.first.update_columns(start_at: 1.day.from_now, finish_at: 1.week.from_now)
            end
          end

          it "cancels participations, generates no invoice" do
            freeze_time

            expect do
              expect do
                put :cancel, params: params
              end.to have_enqueued_mail(Event::ParticipationCanceledMailer, :confirmation).once
            end
              .to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"),
                :count).by(0)
              .and change { participation.reload.state }.to("canceled")
              .and change { ExternalInvoice::CourseAnnulation.count }.by(0)

            expect(participation.canceled_at).to eq(Time.zone.today)
          end
        end
      end

      context "as admin" do
        it "sets statement and default canceled_at" do
          freeze_time
          put :cancel, params: params.merge({event_participation: {cancel_statement: "next time!"}})
          expect(participation.reload.state).to eq "canceled"
          expect(participation.canceled_at).to eq Time.zone.today
          expect(participation.cancel_statement).to eq "next time!"
        end

        it "can override canceled_at" do
          freeze_time
          put :cancel, params: params.merge({event_participation: {canceled_at: 1.day.ago.to_date}})
          expect(participation.reload.state).to eq "canceled"
          expect(participation.canceled_at).to eq 1.day.ago.to_date
          expect(participation.cancel_statement).to be_nil
        end

        it "sends application canceled email when send_email is true" do
          expect {
            put :cancel,
              params: params.merge({event_participation: {canceled_at: 1.day.ago.to_date},
send_email: true})
          }
            .to have_enqueued_mail(Event::ParticipationCanceledMailer, :confirmation).once
        end

        it "does not send application canceled email when send_email is false" do
          expect {
            put :cancel,
              params: params.merge({event_participation: {canceled_at: 1.day.ago.to_date},
send_email: false})
          }
            .not_to have_enqueued_mail(Event::ParticipationCanceledMailer, :confirmation)
        end

        context "for tour" do
          let(:event) do
            Fabricate(:sac_tour, groups: [groups(:bluemlisalp)])
          end

          it "cancels participations, generates no invoice but sends email" do
            freeze_time

            expect do
              expect do
                put :cancel,
                  # rubocop:todo Layout/LineLength
                  params: params.merge({event_participation: {canceled_at: 5.days.ago.to_date}, send_email: false,
# rubocop:enable Layout/LineLength
invoice_option: "standard"})
              end.not_to have_enqueued_mail(Event::ParticipationCanceledMailer, :confirmation)
            end
              .to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"),
                :count).by(0)
              .and change { participation.reload.state }.to("canceled")
              .and change { ExternalInvoice::CourseAnnulation.count }.by(0)

            expect(participation.canceled_at).to eq(5.days.ago.to_date)
          end
        end

        context "invoice_option standard" do
          # rubocop:todo Layout/LineLength
          it "creates course annulation invoice and enqueues cancel invoice job if person has invoice" do
            # rubocop:enable Layout/LineLength
            invoice = participation.person.external_invoices.create!(
              type: ExternalInvoice::SacMembership.sti_name, link: participation
            )
            participation.update!(price: 10, price_category: :price_regular)
            freeze_time

            expect {
              put :cancel,
                params: params.merge({event_participation: {canceled_at: 1.day.ago.to_date},
            invoice_option: "standard"})
            }
              .to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"),
                :count).by(1)
              .and change(Delayed::Job.where("handler LIKE '%CancelInvoiceJob%'"), :count).by(1)
              .and change { invoice.reload.state }.to("cancelled")
              .and change { participation.reload.state }.to("canceled")
              .and change { ExternalInvoice::CourseAnnulation.count }.by(1)

            invoice = ExternalInvoice::CourseAnnulation.find_by(link: participation,
              person: participation.person)
            expect(invoice).to be_present
            expect(invoice.issued_at).to eq(Date.current)
            expect(invoice.sent_at).to eq(Date.current)
            expect(invoice.state).to eq("draft")
            expect(invoice.year).to eq(event.dates.first.start_at.year)
          end
        end

        context "invoice_option custom" do
          it "creates course annulation invoice with custom amount" do
            expect(ExternalInvoice::CourseAnnulation).to receive(:invoice!).with(participation,
              custom_price: 400.50)
            put :cancel,
              params: params.merge({event_participation: {canceled_at: 1.day.ago.to_date},
invoice_option: "custom", custom_price: "400.50"})
          end

          it "custom amount is zero when no amount passed" do
            expect(ExternalInvoice::CourseAnnulation).to receive(:invoice!).with(participation,
              custom_price: 0)
            put :cancel,
              params: params.merge({event_participation: {canceled_at: 1.day.ago.to_date},
invoice_option: "custom", custom_price: ""})
          end
        end

        context "invoice_option no_invoice" do
          it "creates course annulation invoice with custom amount" do
            expect(ExternalInvoice::CourseAnnulation).not_to receive(:invoice!)
            expect do
              put :cancel,
                params: params.merge({event_participation: {canceled_at: 1.day.ago.to_date},
invoice_option: "no_invoice"})
            end.not_to change { ExternalInvoice::CourseAnnulation.count }
          end
        end
      end
    end

    context "PUT#assign" do
      let(:participation) { Fabricate(:event_participation, event: event) }

      it "sets participation state to assigned and sends confirmation mail" do
        expect do
          put :assign,
            params: {
              group_id: group.id,
              event_id: event.id,
              id: participation.id
            }
        end.to change(Delayed::Job.where("handler like '%ParticipationConfirmationJob%'"),
          :count).by(1)

        participation.reload
        expect(participation.active).to be true
        expect(participation.state).to eq "assigned"
      end
    end
  end
end
