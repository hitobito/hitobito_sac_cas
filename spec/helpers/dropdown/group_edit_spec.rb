# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "Dropdown::GroupEdit" do
  include FormatHelper
  include I18nHelper
  include LayoutHelper
  include UtilityHelper

  let(:dropdown) { Dropdown::GroupEdit.new(self, group) }

  subject { dropdown.to_s }

  before do
    allow(self).to receive(:can?).and_return(true)
  end

  context "root group" do
    let(:group) { groups(:root) }

    it "renders sac membership config item" do
      is_expected.to have_selector "a", text: "Parameter für Mitgliedschaftsrechnungen"
    end

    it "does not render sac membership config item without index permission on config" do
      allow(self).to receive(:can?).with(:index, SacMembershipConfig).and_return(false)

      is_expected.to have_no_selector "a", text: "Parameter für Mitgliedschaftsrechnungen"
    end
  end

  context "sektion" do
    let(:group) { groups(:bluemlisalp) }

    it "renders section specific items with permission" do
      allow(group).to receive(:tours_enabled).and_return(true)

      is_expected.to have_selector "a", text: "Parameter für Mitgliedschaftsrechnungen"
      is_expected.to have_selector "a", text: "Freigabe-Zuständigkeiten"
      is_expected.to have_selector "a", text: "E-Mail Vorlagen"
    end

    it "does not render sac membership config item without index permission on config" do
      allow(self).to receive(:can?).with(:index, SacSectionMembershipConfig).and_return(false)

      is_expected.to have_no_selector "a", text: "Parameter für Mitgliedschaftsrechnungen"
    end

    it "does not render edit commission responsibility item without update permission" do
      allow(group).to receive(:tours_enabled).and_return(true)
      allow(self).to receive(:can?).with(:update, group).and_return(false)

      is_expected.to have_no_selector "a", text: "Freigabe-Zuständigkeiten"
      is_expected.to have_no_selector "a", text: "E-Mail Vorlagen"
    end

    it "does not render edit commission responsibility item if tours are disabled" do
      allow(group).to receive(:tours_enabled).and_return(false)

      is_expected.to have_no_selector "a", text: "Freigabe-Zuständigkeiten"
    end
  end

  context "ortsgruppe" do
    let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg) }

    it "renders sac membership config item" do
      is_expected.to have_selector "a", text: "Parameter für Mitgliedschaftsrechnungen"
    end

    it "does not render sac membership config item without index permission on config" do
      allow(self).to receive(:can?).with(:index, SacSectionMembershipConfig).and_return(false)

      is_expected.to have_no_selector "a", text: "Parameter für Mitgliedschaftsrechnungen"
    end

    it "renders edit commission responsibility item" do
      allow(group).to receive(:tours_enabled).and_return(true)

      is_expected.to have_selector "a", text: "Freigabe-Zuständigkeiten"
    end

    it "does not render edit commission responsibility item without update permission" do
      allow(group).to receive(:tours_enabled).and_return(true)
      allow(self).to receive(:can?).with(:update, group).and_return(false)

      is_expected.to have_no_selector "a", text: "Freigabe-Zuständigkeiten"
    end

    it "does not render edit commission responsibility item if tours are disabled" do
      allow(group).to receive(:tours_enabled).and_return(false)

      is_expected.to have_no_selector "a", text: "Freigabe-Zuständigkeiten"
    end
  end
end
