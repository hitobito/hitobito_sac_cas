# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Person::QueryController do
  let(:person) { people(:admin) }

  context "GET index" do
    before { sign_in(person) }

    let(:json) { JSON.parse(response.body) }

    it "finds by birthday" do
      get :index, params: {q: "1993"}

      expect(json).to have(2).items
      expect(response.body).to match(/Magazina Leserat/)
      expect(response.body).to match(/Ida Paschke/)
    end

    it "finds by id" do
      get :index, params: {q: "600004"}

      expect(json).to have(1).item
      expect(response.body).to match(/Nima Norgay/)
    end

    it "returns 20 matches most" do
      25.times { Fabricate(:person, birthday: Date.new(2000, 1, 1)) }
      get :index, params: {q: "2000"}
      expect(json).to have(20).items
    end
  end
end
