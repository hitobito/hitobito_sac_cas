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
    expect(dom).to have_button "Mitgliederstatistik"
  end

  context "member" do
    let(:person) { people(:mitglied) }

    it "hides statistics download button" do
      expect(dom).not_to have_button "Mitgliederstatistik"
    end
  end

  context "sektion group" do
    let(:group) { groups(:bluemlisalp) }

    it "has no statistics download button" do
      expect(dom).not_to have_button "Mitgliederstatistik"
    end
  end
end
