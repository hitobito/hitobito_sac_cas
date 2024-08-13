# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::MembershipInvoicesController, type: :controller do
  let(:person) { people(:mitglied) }
  let(:client) { instance_double(Invoices::Abacus::Client) }

  before { sign_in(people(:admin)) }

  before do
    Role.update_all(delete_on: Time.zone.today.end_of_year)
    SacMembershipConfig.update_all(valid_from: 2015)
    SacSectionMembershipConfig.update_all(valid_from: 2015)
  end

  describe "POST create" do
    it "creates external invoice" do
      person.update!(zip_code: 3600, town: "Thun")

      expect do
        post :create, params: {
          group_id: groups(:bluemlisalp_mitglieder).id,
          person_id: person.id,
          people_membership_invoice: {
            reference_date: Time.zone.today,
            invoice_date: Time.zone.today,
            send_date: Time.zone.today,
            section_id: groups(:bluemlisalp_mitglieder).id,
            discount: "0"
          }
        }
      end.to change { ExternalInvoice.count }.by(1)

      expect(response).to redirect_to(external_invoices_group_person_path(groups(:bluemlisalp_mitglieder).id, person.id))
      expect(flash[:alert]).to be_nil
      expect(flash[:notice]).to eq("Die gewünschte Rechnung wird erzeugt und an Abacus übermittelt")
    end

    it "doesnt create external invoice when params invalid" do
      person.update!(zip_code: 3600, town: "Thun")

      # no send date
      expect do
        post :create, params: {
          group_id: groups(:bluemlisalp_mitglieder).id,
          person_id: person.id,
          people_membership_invoice: {
            reference_date: Time.zone.today,
            invoice_date: Time.zone.today,
            send_date: "",
            section_id: groups(:bluemlisalp_mitglieder).id,
            discount: "0"
          }
        }
      end.to change { ExternalInvoice.count }.by(0)

      expect(response).to redirect_to(new_group_person_membership_invoice_path(groups(:bluemlisalp_mitglieder).id, person.id))
      expect(flash[:alert]).to include("Send date muss ausgefüllt werden")

      # no reference date and no invoice date
      expect do
        post :create, params: {
          group_id: groups(:bluemlisalp_mitglieder).id,
          person_id: person.id,
          people_membership_invoice: {
            reference_date: "",
            invoice_date: "",
            send_date: Time.zone.today,
            section_id: groups(:bluemlisalp_mitglieder).id,
            discount: "0"
          }
        }
      end.to change { ExternalInvoice.count }.by(0)
      expect(response).to redirect_to(new_group_person_membership_invoice_path(groups(:bluemlisalp_mitglieder).id, person.id))
      expect(flash[:alert]).to include("Reference date muss ausgefüllt werden, Invoice date muss ausgefüllt werden")

      # reference date in invalid year
      expect do
        post :create, params: {
          group_id: groups(:bluemlisalp_mitglieder).id,
          person_id: person.id,
          people_membership_invoice: {
            reference_date: Time.zone.today.next_year(5),
            invoice_date: Time.zone.today,
            send_date: Time.zone.today,
            section_id: groups(:bluemlisalp_mitglieder).id,
            discount: "0"
          }
        }
      end.to change { ExternalInvoice.count }.by(0)

      expect(response).to redirect_to(new_group_person_membership_invoice_path(groups(:bluemlisalp_mitglieder).id, person.id))
      expect(flash[:alert]).to include("Reference date muss zwischen 2024-01-01 und 2025-12-31 liegen")

      # set person stammsektion to be continued in next year
      person.sac_membership.stammsektion_role.update!(delete_on: Time.zone.today.next_year.end_of_year)

      # send date cant be next year
      expect do
        post :create, params: {
          group_id: groups(:bluemlisalp_mitglieder).id,
          person_id: person.id,
          people_membership_invoice: {
            reference_date: Time.zone.today,
            invoice_date: Time.zone.today,
            send_date: Time.zone.today.next_year,
            section_id: groups(:bluemlisalp_mitglieder).id,
            discount: "0"
          }
        }
      end.to change { ExternalInvoice.count }.by(0)

      expect(response).to redirect_to(new_group_person_membership_invoice_path(groups(:bluemlisalp_mitglieder).id, person.id))
      expect(flash[:alert]).to include("Send date muss zwischen 2024-01-01 und 2024-12-31 liegen")

      # invalid discount
      expect do
        post :create, params: {
          group_id: groups(:bluemlisalp_mitglieder).id,
          person_id: person.id,
          people_membership_invoice: {
            reference_date: Time.zone.today,
            invoice_date: Time.zone.today,
            send_date: Time.zone.today,
            section_id: groups(:bluemlisalp_mitglieder).id,
            discount: "16"
          }
        }
      end.to change { ExternalInvoice.count }.by(0)

      expect(response).to redirect_to(new_group_person_membership_invoice_path(groups(:bluemlisalp_mitglieder).id, person.id))
      expect(flash[:alert]).to include("Discount ist kein gültiger Wert")
    end
  end
end
