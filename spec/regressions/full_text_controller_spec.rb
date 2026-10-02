# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FullTextController, type: :controller do
  render_views

  let(:dom) { Capybara::Node::Simple.new(response.body) }

  describe "GET #index" do
    let(:group) { groups(:geschaeftsstelle) }

    let(:user) { Fabricate(Group::Geschaeftsstelle::Admin.name.to_sym, group: group).person }

    let(:person) { people(:admin) }

    before do
      sign_in(user)
      allow_any_instance_of(FullTextController).to receive(:only_result).and_return(nil)
    end

    it "renders membership_number column" do
      get :index, params: {q: person.first_name}

      # Search results are ordered by relevance only, so address the person's own row instead
      # of relying on its position among equally ranked results.
      expect(dom.find("#people table thead th:last-child").text).to include "Mitglied-Nr"
      expect(dom.find("#people table tr#person_#{person.id} td:last-child").text)
        .to include person.membership_number.to_s
    end
  end
end
