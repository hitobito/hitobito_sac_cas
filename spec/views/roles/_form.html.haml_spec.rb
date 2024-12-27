#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "roles/_form.html.haml" do
  include FormatHelper

  let(:dom) do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  let(:person) { role.person }

  before do
    assign(:group, group)
    assign(:role, role.decorate)
    assign(:policy_finder, Group::PrivacyPolicyFinder.for(group: group, person: person))
    allow(view).to receive_messages(path_args: [group, role], entry: role.decorate, model_class: Role, current_user: person)
    allow(controller).to receive_messages(current_user: person)
  end

  context "Group::SektionsNeuanmeldungenSektion" do
    let(:role) { Fabricate.build(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name, group: group) }
    let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }

    it "hides start_on" do
      expect(dom).not_to have_field "Von"
    end
  end

  context "Group::SektionsMitglieder" do
    let(:role) { Fabricate.build(Group::SektionsMitglieder::Leserecht.sti_name, group: group) }
    let(:group) { groups(:bluemlisalp_mitglieder) }

    it "renders start_on" do
      expect(dom).to have_field "Von"
    end
  end
end
