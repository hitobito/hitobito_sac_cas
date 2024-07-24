# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::SacFamilyMainPersonController, type: :controller do
  let(:adult) { people(:familienmitglied) }
  let(:adult2) { people(:familienmitglied2) }
  let(:child) { people(:familienmitglied_kind) }

  let(:today) { Time.zone.today }
  let(:end_of_year) do
    if today == today.end_of_year
      (today + 1.days).end_of_year
    else
      today.end_of_year
    end
  end

  let(:mitgliederverwaltung_sektion) do
    person = Fabricate(Group::SektionsFunktionaere::Mitgliederverwaltung.sti_name.to_sym,
      group: groups(:bluemlisalp_funktionaere)).person
    Fabricate(Group::SektionsMitglieder::Schreibrecht.sti_name.to_sym,
      group: groups(:bluemlisalp_mitglieder), person: person)
    person
  end

  describe "PUT #update" do
    before { sign_in mitgliederverwaltung_sektion }

    context "when the person is already the main family person" do
      before { adult.update!(sac_family_main_person: true) }

      it "redirects to the person show view" do
        put :update, params: {id: adult.id}
        expect(response).to redirect_to(adult)
      end
    end

    context "when the person is not associated with any household" do
      before { adult.update!(household_key: nil) }

      it "returns a 422 status with an error message" do
        put :update, params: {id: adult.id}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to eq("Person is not associated with any household")
      end
    end

    context "when the update is successful" do
      it "sets the sac_family_main_person to true for adult1 and false for others" do
        put :update, params: {id: adult.id}
        expect(response).to redirect_to(adult)

        adult.reload
        adult2.reload
        child.reload
        expect(adult.sac_family_main_person).to be_truthy
        expect(adult2.sac_family_main_person).to be_falsey
        expect(child.sac_family_main_person).to be_falsey
      end

      it "sets the sac_family_main_person to true for adult2 and false for others" do
        expect(adult2.sac_family_main_person).to be_falsey

        put :update, params: {id: adult2.id}
        expect(response).to redirect_to(adult2)

        adult.reload
        adult2.reload
        child.reload
        expect(adult.sac_family_main_person).to be_falsey
        expect(adult2.sac_family_main_person).to be_truthy
        expect(child.sac_family_main_person).to be_falsey
      end

      it "only allows adults to become main persons" do
        expect do
          put :update, params: {id: child.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "when the user does not have a Schreibrecht role in the Mitglieder group" do
      let(:mitgliederverwaltung_sektion) do
        Fabricate(Group::SektionsFunktionaere::Mitgliederverwaltung.sti_name.to_sym,
          group: groups(:bluemlisalp_funktionaere)).person
      end

      before do
        sign_in mitgliederverwaltung_sektion
      end

      it "denies access" do
        expect do
          put :update, params: {id: adult.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "when the user does not have permissions" do
      before { sign_in adult }

      it "denies access" do
        expect do
          put :update, params: {id: adult.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
