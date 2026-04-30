#  Copyright (c) 2026, Schweizer Alpenclub SAC. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# encoding: utf-8

require "spec_helper"

describe SacSectionCustomContentsController, type: :controller do
  render_views

  let(:group) { groups(:bluemlisalp) }
  let(:user) { people(:mitglied) }
  let(:test_entry) do
    CustomContent.create!(
      key: "test",
      label: "Test",
      subject: "Test",
      body: "Hej {user}, go here to login: {login-url}",
      placeholders_optional: "user, login-url",
      context: group
    )
  end
  let(:test_entry_attrs) {}

  before do
    Group::SektionsFunktionaere::Administration.create!(
      person: user,
      group: groups(:bluemlisalp_funktionaere)
    )
  end

  before { sign_in(user) }

  describe "GET index" do
    it "should contain all entries" do
      test_entry
      get :index, params: {group_id: group.id}

      expect(response.status).to eq(200)
      expect(assigns(:custom_contents).size).to eq(1)
      expect(response.body).to include("Bearbeiten")
    end
  end

  describe "GET edit" do
    it "should assign entry" do
      get :edit, params: {group_id: group.id, id: test_entry.id}

      expect(response.status).to eq(200)
      expect(response).to render_template(:edit)
      expect(assigns(:custom_content)).to eq(test_entry)
    end
  end

  describe "PUT update" do
    it "should update entry in database" do
      expect do
        put :update, params: {
          group_id: group.id,
          id: test_entry.id,
          custom_content: {
            subject: "New Login",
            body: "Hej {user}, go here to login: {login-url}"
          }
        }
      end.to change { CustomContent.count }.by(0)

      expect(response).to redirect_to(group_sac_section_custom_contents_path(group.id, returning: true))
      expect(test_entry.reload.subject).to eq("New Login")
      expect(test_entry.reload.body.body.to_s).to include("Hej {user}, go here to login: {login-url}")
    end
  end
end
