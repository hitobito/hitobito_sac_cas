# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SacMembershipConfigsController do
  let(:user) { people(:admin) }
  let(:latest_config) { sac_membership_configs(:"2024") }
  let!(:older_config) do
    config = latest_config.dup
    config.valid_from = 2023
    config.save!
    config
  end

  before { sign_in(user) }

  context "GET index" do
    it "redirects to latest config edit" do
      get :index, params: {group_id: Group.root.id}

      expect(response)
        .to redirect_to(edit_group_sac_membership_config_path(group_id: Group.root.id, id: latest_config.id))
    end

    it "redirects to new if no previous config present" do
      SacMembershipConfig.destroy_all

      get :index, params: {group_id: Group.root.id}

      expect(response)
        .to redirect_to(new_group_sac_membership_config_path(group_id: Group.root.id))
    end

    it "cannot be accessed by non admin" do
      sign_in(people(:mitglied))

      expect do
        get :index, params: {group_id: Group.root.id}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "is unavailable if access by other group than root layer" do
      get :index, params: {group_id: groups(:bluemlisalp).id}

      expect(response).to be_not_found
    end
  end

  context "GET show" do
    it "redirects to config edit" do
      get :show, params: {group_id: Group.root.id, id: older_config.id}

      expect(response)
        .to redirect_to(edit_group_sac_membership_config_path(group_id: Group.root.id, id: older_config.id))
    end

    it "cannot be accessed by non admin" do
      sign_in(people(:mitglied))

      expect do
        get :show, params: {group_id: Group.root.id, id: older_config.id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context "GET edit" do
    it "renders config edit form" do
      get :edit, params: {group_id: Group.root.id, id: latest_config.id}

      expect(response).to be_successful
    end

    it "cannot be accessed by non admin" do
      sign_in(people(:mitglied))

      expect do
        get :show, params: {group_id: Group.root.id, id: latest_config.id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context "PATCH update" do
    let(:updated_model_params) do
      {sac_membership_config: {sac_fee_adult: 42}}
    end

    it "updates config and redirects to show/edit form" do
      patch :update, params: {group_id: Group.root.id, id: latest_config.id}.merge(updated_model_params)

      expect(response)
        .to redirect_to(group_sac_membership_config_path(group_id: Group.root.id, id: latest_config.id))

      latest_config.reload
      expect(latest_config.sac_fee_adult).to eq(42)
    end

    it "cannot update valid_from" do
      updated_model_params[:sac_membership_config][:valid_from] = 2020
      patch :update, params: {group_id: Group.root.id, id: latest_config.id}.merge(updated_model_params)

      expect(response)
        .to redirect_to(group_sac_membership_config_path(group_id: Group.root.id, id: latest_config.id))

      latest_config.reload
      expect(latest_config.valid_from).to eq(2024)
    end

    it "cannot be accessed by non admin" do
      sign_in(people(:mitglied))

      expect do
        patch :update, params: {group_id: Group.root.id, id: latest_config.id}.merge(updated_model_params)
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context "DELETE destroy" do
    it "cannot be destroyed" do
      expect do
        delete :destroy, params: {group_id: Group.root.id, id: older_config.id}
      end.to raise_error(ActionController::UrlGenerationError) # aka 404
    end
  end
end
