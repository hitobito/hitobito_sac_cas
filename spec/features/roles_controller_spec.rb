# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe RolesController, js: true do
  let(:admin) { people(:admin) }
  let(:group) { groups(:bluemlisalp_funktionaere) }
  let(:role) { Fabricate(Group::SektionsFunktionaere::Leserecht.sti_name, group:) }

  before { sign_in(admin) }

  def choose_role(label)
    find("#role_type_select #role_type").find("option", exact_text: label).click
  end

  context "new" do
    before { visit new_group_role_path(group_id: group.id) }

    describe "onboarding mail checkbox" do
      it "is hidden if no role_type is selected" do
        expect(page).to have_selector("#send_onboarding_mail", visible: false)
      end

      it "is shown when role_type is selected and is checked per default" do
        choose_role "Präsidium"
        expect(page).to have_selector("#send_onboarding_mail", visible: true)
        expect(find("#send_onboarding_mail")).to be_checked
      end

      it "stays hidden if role_type without onboarding mail option is selected" do
        choose_role "Leserecht"
        expect(page).to have_selector("#send_onboarding_mail", visible: false)
      end
    end
  end

  context "edit" do
    before { visit edit_group_role_path(group_id: group.id, id: role.id) }

    describe "onboarding mail checkbox" do
      it "is hidden per default" do
        expect(page).to have_selector("#send_onboarding_mail", visible: false)
      end

      it "is shown when role_type is selected and is unchecked per default" do
        choose_role "Präsidium"
        expect(page).to have_selector("#send_onboarding_mail", visible: true)
        expect(find("#send_onboarding_mail")).not_to be_checked
      end

      it "stays hidden if role_type without onboarding mail option is selected" do
        choose_role "Leserecht"
        expect(page).to have_selector("#send_onboarding_mail", visible: false)
      end
    end
  end
end
