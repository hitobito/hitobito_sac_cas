# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "people export", :js do
  let(:person) { people(:admin) }
  let(:group) { groups(:bluemlisalp_mitglieder) }

  before { sign_in(person) }

  it "starts recipients export" do
    visit group_people_path(group_id: group.id)
    click_link("Export")
    find_link("CSV").hover
    click_link("Empfänger")

    expect(page).to have_selector(".info-bar .alert-info",
      text: "Die Downloads werden vorbereitet, bitte warten.")
  end
end
