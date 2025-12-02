# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::TerminateAboMagazinAbonnentsController do
  before { sign_in(operator) }

  let(:operator) { person }
  let(:abo_die_alpen) { groups(:abo_die_alpen) }
  let(:role) { roles(:abonnent_alpen) }

  subject(:page) { Capybara::Node::Simple.new(response.body) }

  let(:terminate_abonnent_path) do
    group_person_role_terminate_abo_magazin_abonnent_path(
      group_id: abo_die_alpen.id,
      person_id: person.id,
      role_id: role.id
    )
  end

  def build_params(**attrs)
    {memberships_terminate_abo_magazin_abonnent: attrs}
  end

  def create_invoice(attrs = {})
    person.external_invoices.create!(attrs.merge(type: ExternalInvoice::SacMembership.sti_name))
  end

  def expect_alert(text, css: ".alert-info")
    expect(page).to have_css(css, text:)
  end

  describe "#GET" do
    let(:request) { get(terminate_abonnent_path) }
    let(:person) { people(:abonnent) }

    def expect_form # rubocop:disable Metrics/AbcSize
      expect(page).to have_css "h1", text: "Die Alpen-Abonnent beenden"
      expect(page).not_to have_css "label.required", text: "Austrittsgrund"
      expect(page).to have_css "label.required", text: "Beenden ab"
      expect(page).to have_field "Sofort"
      expect(page).to have_field "Auf 31.12.#{Time.zone.now.year}"
      expect(page).to have_button "Die Alpen-Abonnent beenden", disabled: true
    end

    context "as normal user" do
      it "renders the form" do
        request
        expect_form
      end
    end
  end

  describe "#POST" do
    let(:person) { people(:abonnent) }
    let(:yesterday) { Time.zone.yesterday.to_s }

    def request(params = {})
      defaults = {terminate_on: role.end_on, entry_fee_consent: true, online_articles_consent: true}
      post(terminate_abonnent_path, params: build_params(**defaults.merge(params)))
    end

    def create_invoice(year:, state: :open, link: groups(:abo_die_alpen), type: :abo_magazin_invoice)
      Fabricate(type, person:, link:, state:, year:)
    end

    context "as normal user" do
      it "marks single role as terminated and redirects" do
        create_invoice(year: 2025)
        create_invoice(year: 2026)
        expect do
          request(data_retention_consent: true, subscribe_newsletter: true)
          role.reload
        end
          .to not_change(Role, :count)
          .and change { person.roles.future.count }.by(1)
          .and change { role.terminated }.to(true)
          .and change { person.external_invoices.cancelled.count }.by(1)
          .and not_have_enqueued_mail
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Dein Abonnement wurde gekündet."
      end

      it "validates inputs" do
        expect do
          request(terminate_on: "")
        end.not_to change { role.reload }
        expect(page).to have_css ".alert-danger", text: "Beenden ab ist kein gültiger Wert"
      end
    end

    context "as admin" do
      let(:operator) { people(:admin) }

      it "can choose immediate termination, terminate single role and redirects" do
        expect do
          request(terminate_on: yesterday)
          role.reload
        end.to change(Role, :count).by(-1)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Dein Abonnement wurde gekündet."
      end
    end

    context "as a different user" do
      let(:operator) { people(:familienmitglied) }

      it "returns not authorized" do
        expect { request }.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
