# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::ExternalInvoicesController do
  let(:person) { people(:mitglied) }
  let(:group_id) { person.groups.first.id }

  before { sign_in(person) }

  describe "#show" do
    let(:sample_time) { Time.zone.local(2024, 1, 1, 0, 0, 0, 0) }
    let(:invoice) {
      ExternalInvoice.create!(state: "open", abacus_sales_order_key: "123456", total: 100.0,
        issued_at: sample_time, created_at: sample_time, year: 2024, sent_at: sample_time,
        updated_at: sample_time, person_id: person.id,
        type: "ExternalInvoice")
    }

    context "as member" do
      it "is unauthorized" do
        expect do
          get :index, params: {group_id: group_id, id: person.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as employee" do
      before do
        person.roles.create!(
          group: groups(:geschaeftsstelle),
          type: Group::Geschaeftsstelle::Mitarbeiter.sti_name
        )
      end

      it "redirects to the person's external invoice page" do
        get :show, params: {invoice_id: invoice.id}
        expect(response).to redirect_to external_invoices_group_person_path(person.primary_group.id, person.id)
      end
    end
  end

  context "#index" do
    context "as member" do
      it "is unauthorized" do
        expect do
          get :index, params: {group_id: group_id, id: person.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as employee" do
      render_views
      let(:sample_time) { Time.zone.local(2024, 1, 1, 0, 0, 0, 0) }
      let(:invoice) {
        p sample_time
        ExternalInvoice.create!(state: "open", abacus_sales_order_key: "123456", total: 100.0,
          issued_at: sample_time, created_at: sample_time, year: 2024, sent_at: sample_time,
          updated_at: sample_time, person_id: person.id,
          type: "ExternalInvoice")
      }

      before do
        person.roles.create!(
          group: groups(:geschaeftsstelle),
          type: Group::Geschaeftsstelle::Mitarbeiter.sti_name
        )
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
          p invoice.created_at
          p I18n.l(invoice.created_at, format: "%d.%m.%Y %H:%M")
          Capybara.string(response.body).find("#main").tap do |main|
            expect(main).to have_selector("a", text: "Mitgliedschaftsrechnung erstellen")
            expect(main).to have_selector("th", text: "Titel")
            expect(main).to have_selector("th", text: "Status")
            expect(main).to have_selector("th", text: "Abacus Nummer")
            expect(main).to have_selector("th", text: "Total")
            expect(main).to have_selector("th", text: "Rechnungsdatum")
            expect(main).to have_selector("th", text: "Erstellt")
            expect(main).to have_selector("th", text: "Aktualisiert")

            expect(main).to have_selector("td", text: "Offen")
            expect(main).to have_selector("td", text: invoice.abacus_sales_order_key.to_s)
            expect(main).to have_selector("td", text: invoice.total.to_s)
            expect(main).to have_selector("td", text: I18n.l(invoice.issued_at, format: "%d.%m.%Y"))
            expect(main).to have_selector("td", text: I18n.l(invoice.created_at, format: "%d.%m.%Y %H:%M"))
            expect(main).to have_selector("td", text: I18n.l(invoice.updated_at, format: "%d.%m.%Y %H:%M"))
          end
        end
      end

      context "cancellation button" do
        render_views

        def check_presence_of_cancel_button_after
          yield
          get :index, params: {group_id: group_id, id: person.id}
          invoice.update(state: "open", abacus_sales_order_key: "1234")
          expect(response.body).not_to have_text("Stornieren")
        end

        it "does not show the cancellation button" do
          invoice
          expect(ExternalInvoice.where(person_id: person.id).count).to eq(1)

          check_presence_of_cancel_button_after { invoice.update!(state: "cancelled") }
          check_presence_of_cancel_button_after { invoice.update!(state: "error") }
          check_presence_of_cancel_button_after { invoice.update!(abacus_sales_order_key: nil) }
        end

        it "shows the cancellation button" do
          invoice.update(state: "open", abacus_sales_order_key: "1234")

          get :index, params: {group_id: group_id, id: person.id}

          expect(response.body).to have_selector("a[data-method='post'][href='/de/groups/#{group_id}/people/#{person.id}/external_invoices/#{invoice.id}/cancel']") do |button|
            expect(button).to have_text("Stornieren")
          end
        end
      end
    end

    context "as functionary" do
      before do
        person.roles.create!(
          group: groups(:matterhorn_funktionaere),
          type: Group::SektionsFunktionaere::Administration.sti_name
        )
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
      it "is unauthorized" do
        expect do
          post :cancel, params: {group_id: group_id, id: person.id, invoice_id: invoice.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as employee" do
      before do
        person.roles.create!(
          group: groups(:geschaeftsstelle),
          type: Group::Geschaeftsstelle::Mitarbeiter.sti_name
        )
      end

      it "cancels the invoice" do
        expect(invoice.reload.state).to eq("open")
        post :cancel, params: {group_id: group_id, id: person.id, invoice_id: invoice.id}
        expect(invoice.reload.state).to eq("cancelled")
        expect(flash[:notice]).to eq("Die Rechnung #{invoice.id} (Auftrags-Nr. #{invoice.abacus_sales_order_key}) wird storniert")
        expect(response).to redirect_to(external_invoices_group_person_path(group_id, person.id))
      end
    end

    context "as functionary" do
      before do
        person.roles.create!(
          group: groups(:matterhorn_funktionaere),
          type: Group::SektionsFunktionaere::Administration.sti_name
        )
      end

      it "is not authorized" do
        expect do
          post :cancel, params: {group_id: group_id, id: person.id, invoice_id: invoice.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
