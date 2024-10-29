#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"
describe "groups/_attrs_sac_cas.html.haml" do
  include FormatHelper

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    allow(view).to receive_messages(current_user: Person.new)
    allow(view).to receive_messages(entry: GroupDecorator.decorate(group))
    allow(controller).to receive_messages(current_user: Person.new)
    assign(:sub_groups, "Gruppen" => [], "Untergruppen" => [])
    assign(:group, group)
  end

  context "sektion" do
    let(:group) { groups(:bluemlisalp) }

    it "renders sektions and nav sektions id fields" do
      expect(dom).to have_css "dl dt", text: "Gruppentyp technisch"
      expect(dom).to have_css "dl dd", text: group.class.sti_name

      expect(dom).to have_css "dl dt", text: "Gruppen-ID"
      expect(dom).to have_css "dl dd", text: group.id

      expect(dom).to have_css "dl dt", text: "NAV Sektions-ID"
      expect(dom).to have_css "dl dd", text: group.navision_id
    end

    it "does not render and nav sektions id if blank" do
      group.update_columns(navision_id: nil)
      expect(dom).not_to have_css "dl dt", text: "NAV Sektions-ID"
    end
  end

  context "ortsgruppe" do
    let(:group) { Fabricate(Group::Ortsgruppe.sti_name, parent: groups(:bluemlisalp), navision_id: 123, foundation_year: 2000) }

    it "renders sektions and nav sektions id fields" do
      expect(dom).to have_css "dl dt", text: "Gruppentyp technisch"
      expect(dom).to have_css "dl dd", text: group.class.sti_name

      expect(dom).to have_css "dl dt", text: "Gruppen-ID"
      expect(dom).to have_css "dl dd", text: group.id

      expect(dom).to have_css "dl dt", text: "NAV Sektions-ID"
      expect(dom).to have_css "dl dd", text: group.navision_id
    end
  end

  context "mitglieder" do
    let(:group) { groups(:bluemlisalp_mitglieder) }

    it "does render sektions and nav sektions id fields" do
      expect(dom).to have_css "dl dt", text: "Gruppentyp technisch"
      expect(dom).to have_css "dl dd", text: group.class.sti_name

      expect(dom).to have_css "dl dt", text: "Gruppen-ID"
      expect(dom).not_to have_css "dl dt", text: "NAV Sektions-ID"
    end
  end
end
