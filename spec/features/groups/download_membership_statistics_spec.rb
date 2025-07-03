# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "download membership statistics", js: true do
  let(:admin) { people(:admin) }
  let(:group) { groups(:bluemlisalp) }

  before { sign_in(admin) }

  it "builds the correct download link" do
    visit group_path(id: group.id)
    click_button "Mitgliederstatistik"

    fill_in("Von", with: "01.03.2025")
    find("#download_statistics_from").click
    expect(page).to have_selector(".ui-datepicker-calendar", visible: true)
    find(".ui-datepicker-calendar").click_on("1")
    expect(page).to have_field("Von", with: "01.03.2025")

    fill_in("Bis", with: "01.06.2025")
    find("#download_statistics_to").click
    expect(page).to have_selector(".ui-datepicker-calendar", visible: true)
    find(".ui-datepicker-calendar").click_on("30")
    expect(page).to have_field("Bis", with: "30.06.2025")

    expect(page).to have_link("Herunterladen", href: "https://stats.portal.sac-cas.ch/download?section_id=#{group.id}&from_date=01.03.2025&to_date=30.06.2025")
  end
end
