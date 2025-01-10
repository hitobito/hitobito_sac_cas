# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "person history page" do
  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:geschaeftsstelle) { groups(:geschaeftsstelle) }
  let(:mitglieder) { groups(:bluemlisalp_mitglieder) }

  before { sign_in(admin) }

  describe "her own" do
    it "shows info header about sektionen" do
      visit history_group_person_path(group_id: geschaeftsstelle.id, id: admin.id)
      expect(page).to have_text "Hier kannst du deine Mitgliedschaften verwalten. " \
        "Informationen zu den verschiedenen SAC Sektionen findest du unter " \
        "https://www.sac-cas.ch/de/der-sac/sektionen"
      expect(page).to have_link "https://www.sac-cas.ch/de/der-sac/sektionen"
    end
  end

  describe "others" do
    it "shows info header about sektionen" do
      visit history_group_person_path(group_id: mitglieder.id, id: mitglied.id)
      expect(page).to have_text "Hier kannst du deine Mitgliedschaften verwalten. " \
        "Informationen zu den verschiedenen SAC Sektionen findest du unter " \
        "https://www.sac-cas.ch/de/der-sac/sektionen"
      expect(page).to have_link "https://www.sac-cas.ch/de/der-sac/sektionen"
    end
  end

  context "#membership_years" do
    let(:membership_years) { Role.with_membership_years.find(roles(:mitglied).id).membership_years }

    it "floors membership years" do
      visit history_group_person_path(group_id: mitglieder.id, id: mitglied.id)
      expect(page).to have_css("td:nth-child(5)", text: membership_years.floor.to_s)
      expect(page).not_to have_css("td:nth-child(5)", text: membership_years.to_s)
    end
  end
end
