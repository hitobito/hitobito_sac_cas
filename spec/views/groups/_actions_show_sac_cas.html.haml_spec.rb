#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"
describe "groups/_actions_show_sac_cas.html.haml" do
  let(:person) { people(:admin) }
  let(:group) { groups(:bluemlisalp) }

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    allow(view).to receive_messages(entry: group)
    allow(controller).to receive_messages(current_user: person)
    assign(:group, group)
  end

  it "renders export link" do
    expect(dom).to have_link "CSV Mitglieder", href: "/de/groups/578575972/mitglieder_exports"
  end

  it "renders statistics download button" do
    expect(dom).to have_button "Mitgliederstatistik"
  end

  context "member" do
    let(:person) { people(:mitglied) }

    it "hides export link" do
      expect(dom).not_to have_link "CSV Mitglieder"
    end

    it "hides statistics download button" do
      expect(dom).not_to have_button "Mitgliederstatistik"
    end
  end

  context "Mitglieder group" do
    let(:group) { groups(:bluemlisalp_mitglieder) }

    it "hides statistics download button" do
      expect(dom).not_to have_button "Mitgliederstatistik"
    end
  end
end
