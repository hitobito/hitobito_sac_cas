# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Person::QueryExternalTrainingController do
  context "GET index" do
    before { sign_in(person) }

    let(:json) { JSON.parse(response.body) }

    context "as tourenchef" do
      let(:person) { people(:tourenchef) }
      let(:mitglied) { people(:mitglied) }

      it "find mitglied" do
        get :index, params: {q: "Edmund"}

        expect(json).to have(1).items
        expect(response.body).to match(/Edmund Hillary/)
      end
    end
  end
end
