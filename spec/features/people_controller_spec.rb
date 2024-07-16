# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe PeopleController, js: true do
  subject { page }

  context "table display" do
    let(:person) { people(:admin) }

    before do
      person.roles.destroy_all
      person.roles.create!(
        group: groups(:matterhorn_funktionaere),
        type: Group::SektionsFunktionaere::Administration.sti_name
      )
      sign_in(person)
    end

    it "shows sac remarks fields" do
      visit group_people_path(group_id: person.groups.first.id)
      click_link "Spalten"

      within(".dropdown-menu") do
        expect(page).not_to have_text("Bemerkungen Geschäftsstelle")
        expect(page).to have_text("Bemerkungen Sektion 1")
      end
    end
  end
end
