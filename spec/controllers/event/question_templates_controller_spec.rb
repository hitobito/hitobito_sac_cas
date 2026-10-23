# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::QuestionTemplatesController do
  let(:group) { groups(:bluemlisalp) }
  let(:person) do
    Fabricate(Group::SektionsTourenUndKurse::Tourenchef.sti_name,
      group: groups(:bluemlisalp_touren_und_kurse)).person
  end

  render_views

  before { sign_in(person) }

  describe "GET index" do
    it "is allowed for Tourenchef" do
      get :index, params: {group_id: group.id}
      expect(response).to be_successful
    end

    it "is denied in other layer" do
      expect { get :index, params: {group_id: groups(:matterhorn).id} }
        .to raise_error(CanCan::AccessDenied)
    end
  end

  describe "GET new" do
    it "is allowed for Tourenchef" do
      get :new, params: {group_id: group.id, admin: false}
      expect(response).to be_successful
    end
  end

  describe "POST create" do
    let(:params) do
      {
        group_id: group.id,
        event_question_template: {
          default: true,
          inherit: false,
          question_attributes: {
            question: "Test question",
            type: Event::Question::Default.sti_name,
            admin: false
          }
        }
      }
    end

    it "is allowed for Tourenchef" do
      expect { post :create, params: }.to change { Event::QuestionTemplate.where(group:).count }.by(1)
      expect(response).to redirect_to(group_question_templates_path(group))
    end
  end
end
