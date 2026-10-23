#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"
describe "groups/_actions_show_sac_cas.html.haml" do
  let(:person) { people(:admin) }
  let(:group) { groups(:root) }

  let(:dom) do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  before do
    allow(view).to receive_messages(entry: group)
    allow(controller).to receive_messages(current_user: person)
    assign(:group, group)
  end

  it "renders statistics download button" do
    expect(dom).to have_selector("a.dropdown-toggle", text: "SAC Exporte")
  end

  context "member" do
    let(:person) { people(:mitglied) }

    it "hides statistics download button" do
      expect(dom).not_to have_selector("a.dropdown-toggle", text: "SAC Exporte")
    end
  end

  context "sektion group" do
    let(:group) { groups(:bluemlisalp) }

    it "has no statistics download button" do
      expect(dom).not_to have_selector("a.dropdown-toggle", text: "SAC Exporte")
    end
  end

  describe "question templates button" do
    let(:button_text) { "Vorlagen Anmeldeangaben Anlässe bearbeiten" }
    let(:person) do
      Fabricate(Group::SektionsTourenUndKurse::Tourenchef.sti_name,
        group: groups(:bluemlisalp_touren_und_kurse)).person
    end

    context "on sektion" do
      let(:group) { groups(:bluemlisalp) }

      it "is shown with layer_events_full" do
        expect(dom).to have_link(button_text, href: group_question_templates_path(group))
      end

      context "without permission" do
        let(:person) { people(:mitglied) }

        it { expect(dom).not_to have_link(button_text) }
      end
    end

    context "on ortsgruppe" do
      let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg) }
      let(:person) do
        Fabricate(Group::SektionsTourenUndKurse::Tourenchef.sti_name,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_touren_und_kurse)).person
      end

      it "is shown with layer_events_full" do
        expect(dom).to have_link(button_text, href: group_question_templates_path(group))
      end
    end

    context "on other group types" do
      let(:group) { groups(:bluemlisalp_touren_und_kurse) }

      it { expect(dom).not_to have_link(button_text) }
    end
  end
end
