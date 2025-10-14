#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "roles/_modal.html.haml" do
  include FormatHelper

  let(:group) { role.group }

  let(:dom) {
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    assign(:group, group.decorate) # for core roles/_modal
    assign(:group_selection, group.siblings)
    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:action_name).and_return("new")
    allow(view).to receive_messages(path_args: [group, role], group: group.decorate,
      entry: role.decorate, model_class: Role)
  end

  describe "normal role" do
    let(:role) { roles(:admin) }

    it "has label but and group and type fields" do
      render
      expect(dom).to have_field "Gruppe"
      expect(dom).to have_field "Rolle"
      expect(dom).to have_field "Bezeichnung"
    end
  end

  describe "wizard managed role" do
    let(:role) { roles(:mitglied) }

    it "has label but no group or type fields" do
      render
      expect(dom).not_to have_field "Gruppe"
      expect(dom).not_to have_field "Rolle"
      expect(dom).to have_field "Bezeichnung"
    end
  end
end
