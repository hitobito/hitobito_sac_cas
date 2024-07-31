# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Person::ExternalInvoicesController do
  let(:person) { people(:mitglied) }
  let(:group_id) { person.groups.first.id }

  before { sign_in(person) }

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

      before do
        person.roles.create!(
          group: groups(:geschaeftsstelle),
          type: Group::Geschaeftsstelle::Mitarbeiter.sti_name
        )
        sample_time = Time.zone.local(
          2024, 1, 1, 0, 0, 0, 0
        )
        @invoice = ExternalInvoice.create!(state: "open", abacus_sales_order_key: "123456", total: 100.0,
          issued_at: sample_time, created_at: sample_time, year: 2024, sent_at: sample_time,
          updated_at: sample_time, person_id: person.id,
          type: "ExternalInvoice")

        get :index, params: {group_id: group_id, id: person.id}
      end

      it "is authorized" do
        expect(response).to have_http_status(:success)
      end

      it "renders the external invoice" do
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
          expect(main).to have_selector("td", text: @invoice.abacus_sales_order_key.to_s)
          expect(main).to have_selector("td", text: @invoice.total.to_s)
          expect(main).to have_selector("td", text: I18n.l(@invoice.issued_at, format: "%d.%m.%Y %H:%M:%S.%L"))
          expect(main).to have_selector("td", text: I18n.l(@invoice.created_at, format: "%d.%m.%Y %H:%M"))
          expect(main).to have_selector("td", text: I18n.l(@invoice.updated_at, format: "%d.%m.%Y %H:%M"))
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
end
