# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::ExternalInvoicesController do
  let(:user) { people(:admin) }
  let(:person) { people(:mitglied) }
  let(:group_id) { person.groups.first.id }

  before { sign_in(user) }

  describe "#show" do
    let(:sample_time) { Time.zone.local(2024, 1, 1, 0, 0, 0, 0) }
    let(:invoice) do
      ExternalInvoice.create!(
        state: "open",
        abacus_sales_order_key: "123456",
        total: 100.0,
        issued_at: sample_time,
        created_at: sample_time,
        year: 2024,
        sent_at: sample_time,
        updated_at: sample_time,
        person_id: person.id,
        type: "ExternalInvoice"
      )
    end

    context "as member" do
      let(:user) { person }

      it "is unauthorized" do
        expect do
          get :index, params: {group_id: group_id, id: person.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      it "redirects to the person's external invoice page" do
        get :show, params: {invoice_id: invoice.id}
        expect(response).to redirect_to external_invoices_group_person_path(
          person.primary_group.id, person.id
        )
      end
    end
  end

  context "#index" do
    context "as member" do
      let(:user) { person }

      it "is unauthorized" do
        expect do
          get :index, params: {group_id: group_id, id: person.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      render_views

      let(:sample_time) { Time.zone.local(2024, 1, 1, 0, 0, 0, 0) }
      let(:invoice) do
        ExternalInvoice.create!(state: "open",
          abacus_sales_order_key: "123456",
          total: 100.0,
          issued_at: sample_time,
          created_at: sample_time,
          year: 2024,
          sent_at: sample_time,
          updated_at: sample_time,
          person_id: person.id,
          type: "ExternalInvoice")
      end

      context "external invoice index" do
        before do
          invoice
          get :index, params: {group_id: group_id, id: person.id}
        end

        it "is authorized" do
          expect(response).to have_http_status(:success)
        end

        it "renders the external invoice" do
          page = Capybara.string(response.body)
          expect(page).to have_selector("a", text: "Mitgliedschaftsrechnung erstellen")
          expect(page).to have_selector("th", text: "Titel")
          expect(page).to have_selector("th", text: "Status")
          expect(page).to have_selector("th", text: "Abacus Nummer")
          expect(page).to have_selector("th", text: "Total")
          expect(page).to have_selector("th", text: "Rechnungsdatum")
          expect(page).to have_selector("th", text: "Erstellt")
          expect(page).to have_selector("th", text: "Aktualisiert")

          expect(page).to have_selector("td", text: "Offen")
          expect(page).to have_selector("td", text: invoice.abacus_sales_order_key.to_s)
          expect(page).to have_selector("td", text: invoice.total.to_s)
          expect(page).to have_selector("td", text: I18n.l(invoice.issued_at, format: "%d.%m.%Y"))
          expect(page).to have_selector("td", text: I18n.l(invoice.created_at, format: "%d.%m.%Y %H:%M"))
          expect(page).to have_selector("td", text: I18n.l(invoice.updated_at, format: "%d.%m.%Y %H:%M"))
        end

        context "for non-members" do
          let(:person) { Fabricate(:person) }
          let(:group_id) { Group.root_id }

          it "is authorized" do
            expect(response).to have_http_status(:success)
          end
        end
      end

      context "cancellation button" do
        render_views

        before do
          invoice.update!(state: "open", abacus_sales_order_key: "1234")
        end

        let(:section_admin) do
          Fabricate(
            Group::SektionsFunktionaere::Administration.sti_name,
            group: groups(:bluemlisalp_funktionaere)
          ).person
        end

        let(:cancel_path) { cancel_external_invoices_group_people_group_person_path(group_id, person.id, invoice.id) }

        it "is rendered" do
          get :index, params: {group_id: group_id, id: person.id}
          expect(response.body).to have_selector("a[data-method='post'][href='#{cancel_path}']") do |link|
            expect(link).to have_text("Stornieren")
          end
        end

        it "is missing if not authorized" do
          sign_in(section_admin)
          get :index, params: {group_id: group_id, id: person.id}
          expect(response.body).not_to have_text "Stornieren"
        end

        it "is missing if invoice is cancelled" do
          invoice.update!(state: "cancelled")
          get :index, params: {group_id: group_id, id: person.id}
          expect(response.body).not_to have_text "Stornieren"
        end

        it "is missing if invoice is in state error" do
          invoice.update!(state: "error")
          get :index, params: {group_id: group_id, id: person.id}
          expect(response.body).not_to have_text "Stornieren"
        end

        it "is missing if invoice has no abacus_sales_order_key" do
          invoice.update!(abacus_sales_order_key: nil)
          get :index, params: {group_id: group_id, id: person.id}
          expect(response.body).not_to have_text "Stornieren"
        end
      end
    end

    context "as functionary" do
      let(:user) do
        Fabricate(Group::SektionsFunktionaere::Administration.sti_name,
          group: groups(:matterhorn_funktionaere)).person
      end
      let(:group) { groups(:matterhorn_mitglieder) }

      it "is authorized for section member" do
        get :index, params: {group_id: group.id, id: person.id}
        expect(response).to have_http_status(:success)
      end

      it "is authorized for past section member" do
        person.roles.update_all(end_on: 1.year.ago)

        get :index, params: {group_id: group.id, id: person.id}
        expect(response).to have_http_status(:success)
      end

      it "is actually authorized for anybody" do
        person = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
          group: groups(:bluemlisalp_mitglieder)).person

        get :index, params: {group_id: group.id, id: person.id}
        expect(response).to have_http_status(:success)
      end
    end

    context "as sektion writer" do
      let(:user) do
        Fabricate(Group::SektionsMitglieder::Schreibrecht.sti_name,
          group: groups(:matterhorn_mitglieder)).person
      end

      it "is not authorized" do
        expect do
          get :index, params: {group_id: group_id, id: person.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  context "#cancel" do
    let(:invoice) { Fabricate(:external_invoice, person_id: person.id) }

    context "as member" do
      let(:user) { person }

      it "is unauthorized" do
        expect do
          post :cancel, params: {group_id: group_id, id: person.id, invoice_id: invoice.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      it "cancels the invoice" do
        expect(invoice.reload.state).to eq("open")
        post :cancel, params: {group_id: group_id, id: person.id, invoice_id: invoice.id}
        expect(invoice.reload.state).to eq("cancelled")
        expect(flash[:notice])
          .to eq("Die Rechnung #{invoice.id} (Auftrags-Nr. #{invoice.abacus_sales_order_key}) wird storniert")
        expect(response).to redirect_to(external_invoices_group_person_path(group_id, person.id))
      end
    end

    context "as functionary" do
      let(:user) do
        Fabricate(Group::SektionsFunktionaere::Administration.sti_name,
          group: groups(:matterhorn_funktionaere)).person
      end

      it "is not authorized" do
        expect do
          post :cancel, params: {group_id: group_id, id: person.id, invoice_id: invoice.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
