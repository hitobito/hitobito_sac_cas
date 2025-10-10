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
      let!(:mitglied) { Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym, group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder)).person }

      it "find mitglied" do
        get :index, params: {q: mitglied.first_name}

        expect(json).to have(1).items
        expect(response.body).to match(/#{mitglied.full_name}/)
      end
    end
  end
end
