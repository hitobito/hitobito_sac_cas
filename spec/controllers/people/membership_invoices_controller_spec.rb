# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::MembershipInvoicesController do
  let(:person) { people(:mitglied) }
  let(:today) { Time.zone.today }

  before { sign_in(people(:admin)) }

  let(:params) do
    {
      group_id: groups(:bluemlisalp_mitglieder).id,
      person_id: person.id,
      people_membership_invoice_form: {
        reference_date: today,
        invoice_date: today,
        send_date: today,
        section_id: groups(:bluemlisalp).id,
        discount: 0
      }
    }
  end

  describe "POST create" do
    it "creates external invoice and enqueues job" do
      expect do
        post :create, params: params.deep_merge(people_membership_invoice_form: {discount: 50, new_entry: true})
      end.to change { ExternalInvoice.count }.by(1)
        .and change { Delayed::Job.where("handler like '%CreateInvoiceJob%'").count }

      # todo validate job
      expect(response).to redirect_to(external_invoices_group_person_path(groups(:bluemlisalp_mitglieder).id, person.id))
      expect(flash[:notice]).to eq("Die gewünschte Rechnung wird erzeugt und an Abacus übermittelt")

      job = Delayed::Job.last.payload_object
      expect(job.new_entry).to eq true
      expect(job.discount).to eq 50
      expect(job.reference_date).to eq today
    end

    it "does not create external when invoice form is invalid" do
      expect do
        post :create, params: params.deep_merge(people_membership_invoice_form: {send_date: ""})
      end.not_to change { ExternalInvoice.count }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    # NOTE - these error conditions are probably not possible as invoice_form
    # validates section has a paying role but we stil include them for completeness
    context "unprocessable invoice" do
      before do
        allow_any_instance_of(Invoices::Abacus::MembershipInvoice).to receive(:invoice?).and_return(false)
      end

      it "logs and marks invoice as error if invoice has no memberships" do
        expect do
          allow_any_instance_of(Invoices::Abacus::MembershipInvoice).to receive(:memberships).and_return([])
          post :create, params:
        end.to change { ExternalInvoice.count }.by(1)
          .and change { HitobitoLogEntry.count }.by(1)
          .and not_change { Delayed::Job.count }

        expect(response).to redirect_to(external_invoices_group_person_path(groups(:bluemlisalp_mitglieder).id, person.id))
        expect(flash[:alert]).to eq "Für die gewünschte Sektion besteht am gewählten Datum keine Mitgliedschaft. " \
          "Es wurde entsprechend keine Rechnung erstellt."
      end

      it "logs and marks invoice as error if invoice has memberships" do
        expect do
          allow_any_instance_of(Invoices::Abacus::MembershipInvoice).to receive(:memberships).and_return([:membership])
          post :create, params:
        end.to change { ExternalInvoice.count }.by(1)
          .and change { HitobitoLogEntry.count }.by(1)
          .and not_change { Delayed::Job.count }

        expect(response).to redirect_to(external_invoices_group_person_path(groups(:bluemlisalp_mitglieder).id, person.id))
        expect(flash[:alert]).to eq "Für die gewünschte Person und Sektion fallen keine Mitgliedschaftsgebühren an, " \
          "oder diese sind bereits über andere Rechnungen abgedeckt."
      end
    end

    context "data quality errors" do
      before { person.update!(data_quality: :error) }

      it "logs and marks invoice as error if person has data quality errors" do
        expect { post :create, params: }
          .to change { ExternalInvoice.count }.by(1)
          .and change { HitobitoLogEntry.count }.by(1)
          .and not_change { Delayed::Job.count }

        expect(response).to redirect_to(external_invoices_group_person_path(groups(:bluemlisalp_mitglieder).id, person.id))
        expect(flash[:alert]).to eq "Die gewünschte Person hat Datenqualitätsprobleme. " \
          "Es wurde entsprechend keine Rechnung erstellt."
      end
    end
  end
end
