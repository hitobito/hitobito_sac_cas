# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::MembershipInvoicesController, type: :controller do
  let(:person) { people(:mitglied) }
  let(:today) { Time.zone.today }

  before { sign_in(people(:admin)) }

  before do
    Role.update_all(delete_on: today.end_of_year)
    SacMembershipConfig.update_all(valid_from: 2015)
    SacSectionMembershipConfig.update_all(valid_from: 2015)
  end

  describe "POST create" do
    it "creates external invoice" do
      expect do
        post :create, params: {
          group_id: groups(:bluemlisalp_mitglieder).id,
          person_id: person.id,
          people_membership_invoice_form: {
            reference_date: today,
            invoice_date: today,
            send_date: today,
            section_id: groups(:bluemlisalp_mitglieder).id,
            discount: 0
          }
        }
      end.to change { ExternalInvoice.count }.by(1)

      expect(response).to redirect_to(external_invoices_group_person_path(groups(:bluemlisalp_mitglieder).id, person.id))
      expect(flash[:alert]).to be_nil
      expect(flash[:notice]).to eq("Die gewünschte Rechnung wird erzeugt und an Abacus übermittelt")
    end

    context "invalid params" do
      it "doesnt create external invoice without send date" do
        expect do
          post :create, params: {
            group_id: groups(:bluemlisalp_mitglieder).id,
            person_id: person.id,
            people_membership_invoice_form: {
              reference_date: today,
              invoice_date: today,
              send_date: "",
              section_id: groups(:bluemlisalp_mitglieder).id,
              discount: 0
            }
          }
        end.not_to change { ExternalInvoice.count }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "doesnt create external invoice without referenc and invoice date" do
        expect do
          post :create, params: {
            group_id: groups(:bluemlisalp_mitglieder).id,
            person_id: person.id,
            people_membership_invoice_form: {
              reference_date: "",
              invoice_date: "",
              send_date: today,
              section_id: groups(:bluemlisalp_mitglieder).id,
              discount: 0
            }
          }
        end.not_to change { ExternalInvoice.count }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "doesnt create external invoice if reference date is in invalid year" do
        expect do
          post :create, params: {
            group_id: groups(:bluemlisalp_mitglieder).id,
            person_id: person.id,
            people_membership_invoice_form: {
              reference_date: today.next_year(5),
              invoice_date: today,
              send_date: today,
              section_id: groups(:bluemlisalp_mitglieder).id,
              discount: 0
            }
          }
        end.not_to change { ExternalInvoice.count }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "doesnt create external invoice if reference date is in past year" do
        expect do
          post :create, params: {
            group_id: groups(:bluemlisalp_mitglieder).id,
            person_id: person.id,
            people_membership_invoice_form: {
              reference_date: today.last_year,
              invoice_date: today,
              send_date: today,
              section_id: groups(:bluemlisalp_mitglieder).id,
              discount: 0
            }
          }
        end.not_to change { ExternalInvoice.count }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "doesnt create external invoice send date is next year" do
        expect do
          post :create, params: {
            group_id: groups(:bluemlisalp_mitglieder).id,
            person_id: person.id,
            people_membership_invoice_form: {
              reference_date: today,
              invoice_date: today,
              send_date: today.next_year,
              section_id: groups(:bluemlisalp_mitglieder).id,
              discount: 0
            }
          }
        end.not_to change { ExternalInvoice.count }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "doesnt create external invoice if discount is invalid" do
        expect do
          post :create, params: {
            group_id: groups(:bluemlisalp_mitglieder).id,
            person_id: person.id,
            people_membership_invoice_form: {
              reference_date: today,
              invoice_date: today,
              send_date: today,
              section_id: groups(:bluemlisalp_mitglieder).id,
              discount: 16
            }
          }
        end.not_to change { ExternalInvoice.count }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
