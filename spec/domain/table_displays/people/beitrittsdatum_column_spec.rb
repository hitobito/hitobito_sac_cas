# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::BeitrittsdatumColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied).decorate }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    allow(table).to receive(:template).at_least(:once).and_return(view)
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:bluemlisalp_mitglieder))
  end

  it_behaves_like "table display", {
    column: :beitrittsdatum,
    header: "Beitritt per",
    value: "01.01.2015",
    permission: :show
  } do
    it "reads value from MitgliedZusatzsektion role" do
      Role.where(id: roles(:mitglied).id).update_all(type: Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name)
      display.render(:beitrittsdatum)
      expect(node).to have_css "td", text: "01.01.2015"
    end

    it "ignores value of other role types" do
      Role.where(id: roles(:mitglied).id).update_all(type: Group::SektionsMitglieder::Ehrenmitglied)
      display.render(:beitrittsdatum)
      expect(node).to have_css "td", text: ""
    end

    it "uses min start date when no multiple roles match" do
      allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:root))
      display.render(:beitrittsdatum)
      roles(:mitglied_zweitsektion).update!(start_on: Date.new(2015, 3, 1))
      expect(node).to have_css "td", text: "01.01.2015"
    end
  end
end
