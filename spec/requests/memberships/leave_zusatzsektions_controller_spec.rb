# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::LeaveZusatzsektionsController do
  before { sign_in(operator) }

  let(:operator) { person }
  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:matterhorn) { groups(:matterhorn) }
  let(:role) { person.roles.find_by!(type: "Group::SektionsMitglieder::MitgliedZusatzsektion") }
  let(:primary_role) { person.roles.find_by!(type: "Group::SektionsMitglieder::Mitglied") }

  subject(:page) { Capybara::Node::Simple.new(response.body) }

  def build_params(**attrs)
    {memberships_leave_zusatzsektion_form: attrs}
  end

  def create_invoice(attrs = {})
    person.external_invoices.create!(attrs.merge(type: ExternalInvoice::SacMembership.sti_name))
  end

  def expect_alert(text, css: ".alert-info")
    expect(page).to have_css(css, text:)
  end

  describe "#GET" do
    let(:request) do
      get group_person_role_leave_zusatzsektion_path(group_id: bluemlisalp.id,
        person_id: person.id, role_id: role.id)
    end
    let(:person) { people(:mitglied) }

    def expect_form(dates: %w[now end_of_year]) # rubocop:disable Metrics/AbcSize
      expect(page).to have_css "h1", text: "Zusatzsektion verlassen"
      expect(page).to have_css "label.required", text: "Austrittsgrund"
      if dates.any?
        expect(page).to have_css "label.required", text: "Austrittsdatum"
        expect(page).to have_field "Sofort" if dates.include?("now")
        expect(page).to have_field "Auf 31.12.#{Date.current.year}" if dates.include?("end_of_year")
      else
        expect(page).not_to have_css "label", text: "Austrittsdatum"
      end
      expect(page).to have_button "Austritt beantragen"
    end

    context "as normal user" do
      it "renders the form" do
        request
        expect_form
      end

      context "with payed invoice" do
        it "renders the complete form without invoice" do
          create_invoice(state: :payed)
          request
          expect_form
        end
      end

      context "with open invoice" do
        it "renders form but without terminate_on options in january" do
          travel_to(Time.zone.local(2025, 1, 31)) do
            create_invoice(state: :open)
            request
            expect_alert "Der Austritt kann erst durchgeführt werden nachdem die offene Rechnung bezahlt wurde."
            expect(page).not_to have_css "form"
          end
        end

        it "renders open invoice info abort screen" do
          travel_to(Time.zone.local(2025, 2, 1)) do
            create_invoice(state: :open)
            request
            expect_alert "Der Austritt kann erst durchgeführt werden nachdem die offene Rechnung bezahlt wurde."
            expect(page).not_to have_css "form"
          end
        end
      end
    end

    context "with a terminated membership" do
      before do
        primary_role.write_attribute(:terminated, true)
        primary_role.end_on = Date.new(2024, 12, 31)
        primary_role.save!
      end

      def expect_terminated_page
        expect(response).to be_successful
        expect(response.body).to include "Deine Mitgliedschaft ist gekündigt per"
        expect(response.body).not_to include "Weiter"
      end

      it "renders a notice" do
        travel_to(Time.zone.local(2024, 8, 1)) { request }
        expect_alert "Deine Mitgliedschaft ist gekündigt per 31.12.2024"
        expect(page).not_to have_css "form"
      end

      context "as an admin" do
        let(:operator) { people(:admin) }

        it "renders a notice" do
          travel_to(Time.zone.local(2024, 8, 1)) { request }
          expect_alert "Deine Mitgliedschaft ist gekündigt per 31.12.2024"
          expect(page).not_to have_css("#content form") # does get search form
        end
      end
    end

    context "when sektion has mitglied_termination_by_section_only=true" do
      before do
        role.layer_group.update!(mitglied_termination_by_section_only: true)
      end

      it "returns not authorized" do
        expect { request }.to raise_error(CanCan::AccessDenied)
      end

      context "as and admin" do
        let(:operator) { people(:admin) }

        it "shows the date select step with a warning" do
          request
          expect_alert "Achtung: der Austritt findet bei einer Sektion statt, " \
            "bei der die Austrittsfunktion für das Mitglied deaktiviert ist.", css: ".alert-warning"
          expect_form
        end
      end
    end

    describe "family" do
      context "with a family main person" do
        let(:person) { people(:familienmitglied) }

        it "shows info about affecting the whole family" do
          request
          expect_alert "Achtung: der Austritt wird für die gesamte Familienmitgliedschaft beantragt.",
            css: ".alert-warning"
        end
      end

      context "with a family regular person" do
        let(:person) { people(:familienmitglied2) }

        it "shows info about the main family person" do
          request
          expect_alert "Bitte wende dich an #{people(:familienmitglied)}"
          expect(page).not_to have_css "form"
        end
      end

      context "as a different user" do
        let(:operator) { people(:familienmitglied) }

        it "returns not authorized" do
          expect { request }.to raise_error(CanCan::AccessDenied)
        end
      end

      context "as an admin" do
        let(:operator) { people(:admin) }

        it "shows me the select date step" do
          request
          expect_form
        end
      end
    end
  end

  describe "#POST" do
    let(:termination_reason_id) { termination_reasons(:moved).id }
    def request(params = {})
      defaults = {termination_reason_id:, terminate_on: :end_of_year}
      post(
        group_person_role_leave_zusatzsektion_path(group_id: bluemlisalp.id, person_id: person.id, role_id: role.id),
        params: build_params(**defaults.merge(params))
      )
    end
    let(:person) { people(:mitglied) }

    context "as normal user" do
      it "marks single role as terminated and redirects" do
        expect do
          request
          role.reload
        end.to not_change(Role.with_inactive, :count)
          .and change { role.terminated }.to(true)
          .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
          .and have_enqueued_mail(Memberships::TerminateMembershipMailer, :leave_zusatzsektion).with(
            person,
            matterhorn,
            Date.current.end_of_year,
            true
          )

        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Deine Zusatzmitgliedschaft in <i>SAC " \
          "Matterhorn</i> wurde gelöscht."
      end

      it "validates inputs" do
        expect do
          request(termination_reason_id: nil, terminate_on: :non_existing)
        end.not_to change { role.reload }
        expect(page).to have_css ".alert-danger", text: "Austrittsdatum ist kein gültiger Wert"
        expect(page).to have_css ".alert-danger", text: "Austrittsgrund muss ausgefüllt werden"
      end

      context "with payed invoice" do
        it "marks role as terminated, redirects does not touch invoice" do
          invoice = create_invoice(state: :payed)
          expect do
            request
          end.to change { role.reload.terminated }.to(true)
            .and not_change { invoice.reload }
          expect(response).to redirect_to person_path(person, format: :html)
          expect(flash[:notice]).to eq "Deine Zusatzmitgliedschaft in <i>SAC " \
            "Matterhorn</i> wurde gelöscht."
        end
      end

      context "with open invoice" do
        context "in january" do
          it "renders abort info" do
            travel_to(Time.zone.local(2025, 1, 1)) do
              invoice = create_invoice(state: :open)
              expect do
                request(terminate_on: :now)
              end.not_to change { role.terminated }
              expect(invoice.reload).to be_open
              expect_alert "Der Austritt kann erst durchgeführt werden nachdem die offene Rechnung bezahlt wurde."
            end
          end
        end

        it "renders abort info" do
          travel_to(Time.zone.local(2025, 2, 1)) do
            invoice = create_invoice(state: :open)
            expect do
              request(terminate_on: :now)
            end.not_to change { role.terminated }
            expect(invoice.reload).to be_open
            expect_alert "Der Austritt kann erst durchgeführt werden nachdem die offene Rechnung bezahlt wurde."
          end
        end
      end
    end

    context "as a different user" do
      let(:operator) { people(:familienmitglied) }

      it "returns not authorized" do
        expect { request }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as an admin" do
      let(:operator) { people(:admin) }

      it "can choose immediate termination, terminate single role and redirects" do
        expect do
          request(terminate_on: :now)
          role.reload
        end
          .to change(Role, :count).by(-1)
          .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Deine Zusatzmitgliedschaft in <i>SAC " \
                                     "Matterhorn</i> wurde gelöscht."
      end
    end

    context "as a section admin of zusatzsektion" do
      let(:operator) do
        Group::SektionsFunktionaere::Administration.create!(person: Fabricate(:person),
          group: groups(:matterhorn_funktionaere)).person.reload
      end

      it "can choose immediate termination, terminate single role and redirects" do
        expect do
          request(terminate_on: :now)
          role.reload
        end
          .to change(Role, :count).by(-1)
          .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Deine Zusatzmitgliedschaft in <i>SAC " \
                                     "Matterhorn</i> wurde gelöscht."
      end
    end

    context "as a section admin of main section" do
      let(:operator) do
        Group::SektionsFunktionaere::Administration.create!(person: Fabricate(:person),
          group: groups(:bluemlisalp_funktionaere)).person.reload
      end

      it "returns not authorized" do
        expect { request(terminate_on: :now) }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as family" do
      let(:person) { people(:familienmitglied) }

      it "creates multiple roles and redirects" do
        expect do
          request
          role.reload
        end
          .to not_change(Role.with_inactive, :count)
          .and change { role.terminated }.to(true)
          .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Eure 3 Zusatzmitgliedschaften in <i>SAC " \
                                     "Matterhorn</i> wurden gelöscht."
      end
    end
  end
end
