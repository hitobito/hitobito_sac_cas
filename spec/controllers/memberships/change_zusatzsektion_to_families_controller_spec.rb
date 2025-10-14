# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::ChangeZusatzsektionToFamiliesController do
  let(:params) {
    {group_id: zusatzsektion_role.group_id, person_id: zusatzsektion_role.person_id,
     role_id: zusatzsektion_role.id}
  }

  let(:person) { Fabricate(:person) }
  let(:household) { person.household }

  before do
    household.set_family_main_person!
  end

  let(:stammsektion_class) { Group::SektionsMitglieder::Mitglied }
  let(:zusatzsektion_class) { Group::SektionsMitglieder::MitgliedZusatzsektion }
  let!(:stammsektion_role) { create_role!(stammsektion_class, groups(:bluemlisalp_mitglieder)) }
  let!(:zusatzsektion_role) {
    create_role!(zusatzsektion_class, groups(:matterhorn_mitglieder), beitragskategorie: :adult)
  }

  def latest_zusatzsektion_role = person.roles.where(type: zusatzsektion_class.sti_name).last

  before { sign_in(current_user) }

  def create_role!(role_class, group, beitragskategorie: "family", **opts)
    Fabricate(
      role_class.sti_name,
      group:,
      beitragskategorie:,
      **opts.reverse_merge(
        person:,
        start_on: Time.current.beginning_of_year,
        end_on: Date.current.end_of_year
      )
    )
  end

  context "POST #create" do
    context "as backoffice" do
      let(:current_user) { people(:admin) }

      it "is authorized" do
        expect(zusatzsektion_role.reload.beitragskategorie).to eq("adult")

        post :create, params: params

        expect(zusatzsektion_role.reload.end_on).to be_present
        expect(person.roles.last.beitragskategorie).to eq("family")

        expect(response).to have_http_status(302)
        # rubocop:todo Layout/LineLength
        expect(flash[:notice]).to eq("Rolle wurde erfolgreich zu einer Familienmitgliedschaft geändert.")
        # rubocop:enable Layout/LineLength
      end
    end

    context "as mitglied" do
      let(:current_user) { people(:mitglied) }

      it "is unauthorized" do
        expect do
          post :create, params: params
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
