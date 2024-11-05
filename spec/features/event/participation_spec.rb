# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Participation, :js do
  let(:admin) { people(:admin) }
  let(:participant) { people(:mitglied) }
  let(:event) { Fabricate(:sac_open_course) }
  let(:participation) { Fabricate(:event_participation, event:, person: participant, price_category: "price_member", price: 10, application_id: -1) }

  context "as participant" do
    before { sign_in(participant) }

    it "doesn't show invoice button" do
      visit group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id)
      expect(page).not_to have_button("Rechnung erstellen")
    end
  end

  context "as admin" do
    before { sign_in(admin) }

    it "creates invoice after accepting confirm alert" do
      visit group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id)
      accept_confirm { click_on("Rechnung erstellen") }
      expect(page).to have_css(".alert", text: "Rechnung wurde erfolgreich erstellt.")
    end

    it "doesn't create invoice when rejecting confirm alert" do
      visit group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id)
      dismiss_confirm { click_on("Rechnung erstellen") }
      expect(page).not_to have_css(".alert")
    end

    it "can cancel participation and supply a reason in popover" do
      visit group_event_participation_path(group_id: event.group_ids.first, event_id: event.id, id: participation.id)
      within(".btn-toolbar") do
        click_on "Abmelden"
      end
      within(".popover") do
        fill_in "Begründung", with: "Some Reason"
        click_on "Abmelden"
      end
      expect(page).to have_content "Edmund Hillary wurde abgemeldet."
    end
  end
end
