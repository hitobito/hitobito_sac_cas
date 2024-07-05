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

    before { sign_in(user) }

    it "renders membership_number column" do
      get :index, params: {q: Person.first.first_name}

      expect(dom.all(:css, ".table thead th:last")[0].text).to include "Mitglied-Nr"
      expect(dom.all(:css, ".table tr td:last")[0].text).to include Person.first.membership_number.to_s
    end
  end
end
