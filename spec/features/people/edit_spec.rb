# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "person edit page" do
  let(:admin) { people(:admin) }
  let(:member) { people(:mitglied) }

  before { sign_in(admin) }

  describe "required fields" do
    it "shows error that fields should be filled out" do
      visit edit_group_person_path(group_id: member.group_ids.first, id: member.id)
      fill_in "Nachname", with: ""
      fill_in "person[street]", with: ""
      click_button "Speichern", match: :first
      expect(page).to have_text("Nachname muss ausgefüllt werden")
      expect(page).to have_text("Strasse muss ausgefüllt werden")
    end
  end
end
