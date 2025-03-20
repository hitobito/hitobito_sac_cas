# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::Membership::VerifyController do
  let(:person) { people(:mitglied) }
  let!(:token) { person.membership_verify_token }

  # Do not raise server errors to avoid "No route matches [GET] /favicon.ico" in requests without user
  before { Capybara.raise_server_errors = false }

  it "shows invalid token information" do
    visit "/verify_membership/nOnExistentTOOKen"
    expect(page).to have_text "Ungültiger Verifikationscode"
  end

  context "with valid token" do
    let(:full_name) { "Edmund Hillary" }

    it "shows invalid membership information" do
      person.roles.destroy_all

      visit "/verify_membership/#{token}"
      expect(page).to have_css(".alert-danger", text: "Mitgliedschaft ungültig")
    end

    context "check output structure" do
      it "shows valid membership information" do
        visit "/verify_membership/#{person.membership_verify_token}"
        expect(page).to have_text full_name
        expect(page).to have_text "Mitglied (Stammsektion) (Einzel)\nSAC Blüemlisalp"
        expect(page).to have_text "Mitglied (Zusatzsektion) (Einzel)\nSAC Matterhorn"
        expect(page).to have_css(".alert-success", text: "Mitgliedschaft gültig")
        expect(page).not_to have_text "Aktive/r Tourenleiter/in"
      end

      it "has sponsor information" do
        visit "/verify_membership/#{person.membership_verify_token}"
        expect(page).to have_css("#details #sponsors")
        expect(page).to have_css("#details #logo-reciprocate")
      end

      it "has name and member info before the alert" do
        visit "/verify_membership/#{person.membership_verify_token}"
        expect(page.body.index(full_name)).to be < page.body.index("Mitgliedschaft gültig")
        expect(page.body.index("Mitglied (Stammsektion) (Einzel")).to be > page.body.index("Mitgliedschaft gültig")
      end
    end

    context "as active tour guide" do
      let(:person) { people(:mitglied) }

      it "shows tour guide information" do
        person.qualifications.create!(
          qualification_kind: qualification_kinds(:ski_leader),
          start_at: 1.month.ago
        )
        person.roles.create!(
          type: Group::SektionsTourenUndKurse::Tourenleiter.sti_name,
          group: groups(:matterhorn_touren_und_kurse)
        )

        visit "/verify_membership/#{token}"
        expect(page).to have_text "Aktive/r Tourenleiter/in"
      end
    end
  end
end
