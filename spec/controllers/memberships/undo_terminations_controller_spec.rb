# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::UndoTerminationsController, versioning: true do
  before { PaperTrail.request.controller_info = {mutation_id: Random.uuid} }

  let(:params) {
    {group_id: Group.root, person_id: terminated_role.person_id, role_id: terminated_role.id}
  }
  let(:role) { roles(:familienmitglied) }

  let(:terminated_role) do
    Memberships::TerminateSacMembership.new(
      role, Date.current.yesterday, termination_reason_id: termination_reasons(:deceased).id
    ).save!
    role.reload
  end

  before { sign_in(current_user) }

  context "GET #new" do
    context "as backoffice" do
      let(:current_user) { people(:admin) }

      it "is authorized" do
        get :new, params: params

        expect(response).to have_http_status(200)
      end
    end

    context "as mitglied" do
      let(:current_user) { people(:mitglied) }

      it "is unauthorized" do
        expect do
          get :new, params: params
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  context "POST #create" do
    context "as backoffice" do
      let(:current_user) { people(:admin) }

      it "is authorized" do
        expect(terminated_role).to be_terminated
        post :create, params: params

        terminated_role.reload
        expect(terminated_role).to_not be_terminated

        expect(response).to have_http_status(302)
        expect(flash[:notice]).to eq("Rollen wurden erfolgreich reaktiviert.")
      end

      it "with validation errors" do
        # create new role starting today so undoing the termination will be invalid (date collision)
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
          person: terminated_role.person,
          group: terminated_role.group,
          start_on: Date.current)

        expect do
          post :create, params: params

          expect(response).to have_http_status(200)
          expect(response).to render_template(:new)
        end.not_to change { terminated_role.reload.terminated? }.from(true)
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
