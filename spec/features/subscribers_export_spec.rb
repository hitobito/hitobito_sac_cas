# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "subscribers export", :js do
  let(:person) { people(:root) }
  let(:mailing_list) { mailing_lists(:newsletter) }

  before { sign_in(person) }

  it "starts recipients export" do
    visit group_mailing_list_subscriptions_path(
      group_id: mailing_list.group_id,
      mailing_list_id: mailing_list.id
    )

    click_link("Export")
    find_link("CSV").hover
    click_link("Für den elektronischen Versand (E-Mail)")

    expect(page).to have_selector(".info-bar .alert-info",
      text: "Die Downloads werden vorbereitet, bitte warten.")
  end

  it "starts recipient households export" do
    visit group_mailing_list_subscriptions_path(
      group_id: mailing_list.group_id,
      mailing_list_id: mailing_list.id
    )

    click_link("Export")
    find_link("CSV").hover
    click_link("Für den postalischen Versand")

    expect(page).to have_selector(".info-bar .alert-info",
      text: "Die Downloads werden vorbereitet, bitte warten.")
  end
end
