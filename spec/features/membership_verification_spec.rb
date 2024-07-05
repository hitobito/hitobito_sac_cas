# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::Membership::VerifyController do
  let(:person) { people(:mitglied) }
  let!(:token) { person.membership_verify_token }

  it "shows invalid token information" do
    visit "/verify_membership/nOnExistentTOOKen"
    expect(page).to have_text "Ungültiger Verifikationscode"
  end

  context "with valid token" do
    it "shows invalid membership information" do
      person.roles.destroy_all

      visit "/verify_membership/#{token}"
      expect(page).to have_css(".alert-danger", text: "Mitgliedschaft ungültig")
    end

    it "shows valid membership information" do
      visit "/verify_membership/#{token}"
      expect(page).to have_text "Edmund Hillary"
      # TODO re-activate when adding sac custom extensions
      # expect(page).to have_text 'Mitglied (Stammsektion) (Einzel) - SAC Blüemlisalp'
      expect(page).to have_css(".alert-success", text: "Mitgliedschaft gültig")
      expect(page).not_to have_text "Aktive/r Tourenleiter/in"
    end

    context "as active tour guide" do
      let(:person) { people(:mitglied) }

      it "shows tour guide information" do
        person.qualifications.create!(
          qualification_kind: qualification_kinds(:ski_leader),
          start_at: 1.month.ago
        )
        person.roles.create!(
          type: Group::SektionsTourenkommission::Tourenleiter.sti_name,
          group: groups(:matterhorn_tourenkommission)
        )

        visit "/verify_membership/#{token}"
        expect(page).to have_text "Aktive/r Tourenleiter/in"
      end
    end
  end
end
