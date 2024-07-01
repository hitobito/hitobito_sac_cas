# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "leave zusatzsektion", js: true do
  before do
    sign_in(person)
  end

  context "as normal user" do
    let(:group) { groups(:bluemlisalp_mitglieder) }
    let(:person) { people(:mitglied) }
    let(:role) { person.roles.second }

    it "can execute wizard" do
      visit history_group_person_path(group_id: group.id, id: person.id)
      within("#role_#{role.id}") do
        click_link "Austritt"
      end
      expect(page).to have_title "Zusatzsektion verlassen"
      choose "Sofort"
      click_button "Weiter"
      select "einfach so"
      expect do
        click_button "Austritt beantragen"
        expect(page).to have_content "Deine Zusatzmitgliedschaft in #{role.group.parent.name} wurde gelöscht."
      end
        .to change { person.roles.count }.by(-1)
        .and change { role.reload.deleted_at }.from(nil)
    end
  end
end
