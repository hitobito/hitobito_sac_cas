# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::TerminateSacMembershipsController do
  before { sign_in(operator) }

  let(:operator) { person }
  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:matterhorn) { groups(:matterhorn) }
  let(:person) { role.person }

  subject(:page) { Capybara::Node::Simple.new(response.body) }

  let(:terminate_sac_membership_path) do
    group_person_role_terminate_sac_membership_path(
      group_id: bluemlisalp.id,
      person_id: person.id,
      role_id: role.id
    )
  end

  def build_params(**attrs)
    {memberships_terminate_sac_membership_form: attrs}
  end

  def create_invoice(attrs = {})
    person.external_invoices.create!(attrs.merge(type: ExternalInvoice::SacMembership.sti_name))
  end

  def expect_alert(text, css: ".alert-info")
    expect(page).to have_css(css, text:)
  end

  describe "#GET" do
    let(:request) { get(terminate_sac_membership_path) }
    let(:role) { roles(:mitglied) }

    def field_id(key) = "memberships_terminate_sac_membership_form_#{key}"

    def expect_form(dates: %w[now end_of_year], family: false) # rubocop:disable Metrics/AbcSize
      expect(page).to have_css "h1", text: "SAC-Mitgliedschaft beenden"
      expect(page).to have_css "label.required", text: "Austrittsgrund"
      if dates.many?
        expect(page).to have_css "label.required", text: "Austrittsdatum"
        expect(page).to have_field "Sofort" if dates.include?("now")
        expect(page).to have_field "Auf 31.12.#{Date.current.year}" if dates.include?("end_of_year")
      else
        expect(page).not_to have_css "label", text: "Austrittsdatum"
        field = page.find("input[type=hidden]", visible: false, id: field_id(:terminate_on))
        expect(field[:name]).to eq "memberships_terminate_sac_membership_form[terminate_on]"
        expect(field[:value]).to eq "now"
      end
      expect(page).to have_button "Austritt beantragen", disabled: true
    end

    context "as normal user" do
      it "renders the complete" do
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

      context "with open invoice in current year" do
        it "renders form but with single hidden terminate_on field in january" do
          travel_to(Time.zone.local(2025, 1, 31)) do
            create_invoice(state: :open, year: 2025)
            request
            expect_form(dates: %w[now])
          end
        end

        it "renders open invoice info abort screen" do
          travel_to(Time.zone.local(2025, 2, 1)) do
            create_invoice(state: :open, year: 2025)
            request
            expect_alert "Der Austritt kann erst durchgeführt werden nachdem die offene Rechnung bezahlt wurde."
            expect(page).not_to have_css "form"
          end
        end
      end

      context "with open invoice in previous year" do
        it "renders the form" do
          travel_to(Time.zone.local(2025, 1, 1)) do
            create_invoice(state: :open, year: 2024)
            request
            expect_form
          end
        end
      end
    end

    context "with a terminated membership" do
      before do
        role.write_attribute(:terminated, true)
        role.end_on = Date.new(2024, 12, 31)
        role.save!
      end

      it "renders terminated membership info screen notice" do
        travel_to(Time.zone.local(2024, 8, 1)) { request }
        expect_alert "Deine Mitgliedschaft ist gekündigt per 31.12.2024"
        expect(page).not_to have_css "form"
      end

      context "as an admin" do
        let(:operator) { people(:admin) }

        it "renders terminated membership info screen notice but also form" do
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

        it "shows form" do
          request
          expect_form
        end
      end
    end

    describe "family" do
      context "with family main person" do
        let(:role) { roles(:familienmitglied) }

        it "shows info about affecting the whole family" do
          request
          expect_form(family: true)
        end
      end

      context "with family regular person" do
        let(:role) { roles(:familienmitglied2) }

        it "shows info about the main family person" do
          request
          expect_alert "Austritt wird nur für dich durchgeführt. Ein Familienaustritt " \
            "kann nur von Tenzing Norgay durchgeführt werden.", css: ".alert-info"
          expect_form
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
      post(terminate_sac_membership_path, params: build_params(**defaults.merge(params)))
    end

    let(:role) { roles(:mitglied) }

    context "as normal user" do
      it "marks single role as terminated and redirects" do
        expect do
          request
          role.reload
        end
          .to not_change(Role, :count)
          .and change { role.terminated }.to(true)
          .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
          .and have_enqueued_mail(Memberships::TerminateMembershipMailer, :terminate_membership).with(
            person,
            bluemlisalp,
            Date.current.end_of_year,
            true
          )
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Deine SAC-Mitgliedschaft wurde gekündet."
      end

      it "terminates without sending email to member" do
        expect do
          request(inform_mitglied_via_email: false)
        end.to change { role.reload.terminated }.to(true)
          .and have_enqueued_mail(Memberships::TerminateMembershipMailer, :terminate_membership).with(
            person,
            bluemlisalp,
            Date.current.end_of_year,
            false
          )
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
          expect(flash[:notice]).to eq "Deine SAC-Mitgliedschaft wurde gekündet."
        end
      end

      context "with open invoice in current year" do
        context "in january" do
          around { |example| travel_to(Time.zone.local(2025, 1, 31)) { example.run } }

          it "marks role as terminated and cancels invoice" do
            invoice = create_invoice(state: :open, year: 2025)
            expect do
              request(terminate_on: :now)
            end.to change { role.reload.terminated }.to(true)
              .and change { invoice.reload.state }.from("open").to("cancelled")
          end

          it "does not accept end_of_year as terminate_on" do
            create_invoice(state: :open, year: 2025)
            request(terminate_on: :end_of_year)
            expect(response).to be_unprocessable
          end
        end

        it "renders abort info" do
          travel_to(Time.zone.local(2025, 2, 1)) do
            invoice = create_invoice(state: :open, year: 2025)
            expect do
              request(terminate_on: :now)
            end.not_to change { role.terminated }
            expect(invoice.reload).to be_open
            expect_alert "Der Austritt kann erst durchgeführt werden nachdem die offene Rechnung bezahlt wurde."
          end
        end
      end

      context "with open invoice in previous year" do
        it "marks single role as terminated and redirects" do
          travel_to(Time.zone.local(2025, 2, 1)) do
            invoice = create_invoice(state: :open, year: 2024)
            expect do
              request
            end.to change { role.reload.terminated }.to(true)
              .and not_change { invoice.reload }
            expect(response).to redirect_to person_path(person, format: :html)
            expect(flash[:notice]).to eq "Deine SAC-Mitgliedschaft wurde gekündet."
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
          .to change(Role, :count).by(-2)
          .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Deine SAC-Mitgliedschaft wurde gekündet."
      end
    end

    context "as a section admin" do
      let(:operator) do
        Group::SektionsFunktionaere::Administration.create!(person: Fabricate(:person),
          group: groups(:bluemlisalp_funktionaere)).person.reload
      end

      it "can choose immediate termination, destroy single role and redirects" do
        expect do
          request(terminate_on: :now)
          role.reload
        end
          .to change(Role, :count).by(-2)
          .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Deine SAC-Mitgliedschaft wurde gekündet."
      end
    end

    context "as a section member editor" do
      let(:operator) do
        Group::SektionsMitglieder::Schreibrecht.create!(person: Fabricate(:person),
          group: groups(:bluemlisalp_mitglieder)).person.reload
      end

      it "can choose immediate termination, destroy single role and redirects" do
        expect do
          request(terminate_on: :now)
          role.reload
        end
          .to change(Role, :count).by(-2)
          .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Deine SAC-Mitgliedschaft wurde gekündet."
      end
    end

    context "as a section arbitrary group editor" do
      let(:operator) do
        Group::SektionsFunktionaere::Schreibrecht.create!(person: Fabricate(:person),
          group: groups(:bluemlisalp_funktionaere)).person.reload
      end
      let(:params) { build_params(terminate_on: :now) }

      it "returns not authorized" do
        expect { request }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as a section admin of another section" do
      let(:operator) do
        Group::SektionsFunktionaere::Administration.create!(person: Fabricate(:person),
          group: groups(:matterhorn_funktionaere)).person.reload
      end
      let(:params) {
        build_params(step: 1, termination_choose_date: {terminate_on: "now"},
          summary: {termination_reason_id:})
      }

      it "returns not authorized" do
        expect { request }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as family" do
      let(:role) { roles(:familienmitglied) }

      def household_key_count = Person.where(household_key: "4242").count

      context "now" do
        it "ends multiple roles, dissolves household and redirects" do
          expect do
            request(terminate_on: :now)
            role.reload
          end
            .to change(Role, :count).by(-6)
            .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
            .and change { household_key_count }.by(-3)
          expect(response).to redirect_to person_path(person, format: :html)
          expect(flash[:notice]).to eq "Eure 3 SAC-Mitgliedschaften wurden gekündet."
        end

        context "as non main person" do
          let(:role) { roles(:familienmitglied2) }

          it "ends roles, removes from household and redirects" do
            expect do
              request(terminate_on: :now)
              role.reload
            end
              .to change(Role, :count).by(-2)
              .and change { roles(:familienmitglied2).reload.termination_reason_id }.from(nil).to(termination_reason_id)
              .and change { household_key_count }.by(-1)
            expect(response).to redirect_to person_path(person, format: :html)
            expect(flash[:notice]).to eq "Deine SAC-Mitgliedschaft wurde gekündet."
          end

          it "abouts if household has any errors" do
            role = roles(:familienmitglied_kind)
            Roles::Termination.new(role:, terminate_on: Time.zone.today.end_of_year).call
            expect do
              request(terminate_on: :now)
            end.to not_change(Role, :count)
              .and not_change { household_key_count }
            expect_alert("Nima Norgay hat einen Austritt geplant", css: ".alert-danger ul li")
          end
        end
      end

      context "end of year" do
        it "terminates multiple roles, keeps household and redirects" do
          expect do
            request
            role.reload
          end
            .to not_change(Role, :count)
            .and change { role.terminated }.to(true)
            .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
            .and not_change { household_key_count }
          expect(response).to redirect_to person_path(person, format: :html)
          expect(flash[:notice]).to eq "Eure 3 SAC-Mitgliedschaften wurden gekündet."
        end

        context "as non main person" do
          let(:role) { roles(:familienmitglied2) }

          it "terminates single role, keeps from household and redirects" do
            expect do
              request
              role.reload
            end
              .to not_change(Role, :count)
              .and change { role.terminated }.to(true)
              .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
              .and not_change { household_key_count }
            expect(response).to redirect_to person_path(person, format: :html)
            expect(flash[:notice]).to eq "Deine SAC-Mitgliedschaft wurde gekündet."
          end
        end
      end
    end
  end
end
