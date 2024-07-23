# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require_relative "people_managers_shared_examples"

describe Person::ManagersController do
  context "#create" do
    render_views

    it "responds with error" do
      sign_in(people(:admin))

      post :create, params: {person_id: people(:mitglied), people_manager: { managed_id: people(:familienmitglied_kind)} }

      expect(response).to have_http_status(:unprocessable_entity)
      html = Capybara::Node::Simple.new(response.body)
      expect(html).to have_css(".alert-danger", text: "You are not authorized to access this page")
    end
  end

  it_behaves_like "people_managers#destroy"
end
