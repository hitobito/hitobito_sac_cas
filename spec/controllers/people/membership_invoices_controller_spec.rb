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
    SacMembershipConfig.update_all(valid_from: 2015)
    SacSectionMembershipConfig.update_all(valid_from: 2015)
    expect(Invoices::Abacus::Client).to receive(:new).and_return(client)
  end

  describe "POST create" do
    it "sends invoice to abacus" do
      person.update!(zip_code: 3600, town: "Thun")

      expect(client).to receive(:create).with(:subject, Hash).and_return({id: 7})
      expect(client).to receive(:create).with(:address, Hash)
      expect(client).to receive(:create).with(:communication, Hash)
      expect(client).to receive(:create).with(:customer, Hash)
      expect(client).to receive(:create).with(:sales_order, Hash).and_return({sales_order_id: 19})
      expect(client).to receive(:endpoint).with(:sales_order, Hash)
      expect(client).to receive(:request).with(:post, String, Hash)

      expect do
        post :create, params: {group_id: groups(:bluemlisalp_mitglieder).id, person_id: person.id, date: "2015-03-01"}
      end.to change { ExternalInvoice.count }.by(1)

      expect(response).to redirect_to(group_person_path(groups(:bluemlisalp_mitglieder).id, person.id))
      expect(flash[:alert]).to be_nil
      expect(flash[:notice]).to eq("Die Rechnung wurde erfolgreich an Abacus übermittelt. Auftrag-Nr. 19")
    end

    it "handles failure in abacus request" do
      person.update!(zip_code: 3600, town: "Thun")

      expect(client).to receive(:create).with(:subject, Hash).and_return({id: 7})
      expect(client).to receive(:create).with(:address, Hash)
      expect(client).to receive(:create).with(:communication, Hash)
      expect(client).to receive(:create).with(:customer, Hash)
      expect(client).to receive(:create).with(:sales_order, Hash).and_raise("Something went wrong")

      expect do
        post :create, params: {group_id: groups(:bluemlisalp_mitglieder).id, person_id: person.id, date: "2015-03-01"}
      end.to change { ExternalInvoice.count }.by(1)

      expect(response).to redirect_to(group_person_path(groups(:bluemlisalp_mitglieder).id, person.id))
      expect(flash[:alert]).to eq("Die Rechnung konnte nicht an Abacus übermittelt werden. Fehlermeldung: Something went wrong")
    end

    it "cannot send abacus if address is incomplete" do
      people(:mitglied).update!(zip_code: nil, town: nil)
      post :create, params: {group_id: groups(:bluemlisalp_mitglieder).id, person_id: person.id, date: "2015-03-01"}

      expect(response).to redirect_to(group_person_path(groups(:bluemlisalp_mitglieder).id, person.id))
      expect(flash[:alert]).to eq("Die Rechnung konnte nicht an Abacus übermittelt werden. Fehlermeldung: Ort muss ausgefüllt werden, PLZ muss ausgefüllt werden")
    end
  end
end
