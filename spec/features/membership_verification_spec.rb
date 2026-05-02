# frozen_string_literal: true

#  Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Passes::VerificationsController do
  let(:person) { people(:mitglied) }
  let(:pass_definition) { pass_definitions(:sac_membership) }
  let!(:pass) { Fabricate(:pass, person: person, pass_definition: pass_definition) }

  # rubocop:todo Layout/LineLength
  # Do not raise server errors to avoid "No route matches [GET] /favicon.ico" in requests without user
  # rubocop:enable Layout/LineLength
  before { Capybara.raise_server_errors = false }

  it "shows invalid token information" do
    visit "/passes/verify/nOnExistentTOOKen"
    expect(page).to have_text "Pass ist ungültig"
  end

  context "with valid token" do
    let(:full_name) { "Edmund Hillary" }

    it "shows invalid membership information" do
      pass.update!(state: :ended)

      visit "/passes/verify/#{pass.verify_token}"
      expect(page).to have_css(".alert-warning", text: "Pass ist abgelaufen")
    end

    context "check output structure" do
      it "shows valid membership information" do
        visit "/passes/verify/#{pass.verify_token}"
        expect(page).to have_text full_name
        expect(page).to have_text "Mitglied (Stammsektion) (Einzel)\nSAC Blüemlisalp"
        expect(page).to have_text "Mitglied (Zusatzsektion) (Einzel)\nSAC Matterhorn"
        expect(page).to have_css(".alert-success", text: "Pass ist gültig")
        expect(page).not_to have_text "Aktive/r Tourenleiter/in"
      end

      it "has sponsor information" do
        visit "/passes/verify/#{pass.verify_token}"
        expect(page).to have_css("#sponsors")
        expect(page).to have_css("#logo-reciprocate")
      end

      it "shows name and member info before the alert" do
        visit "/passes/verify/#{pass.verify_token}"
        expect(page.body.index(full_name)).to be < page.body.index("Pass ist gültig")
        expect(page.body.index("Mitglied (Stammsektion) (Einzel")).to be < page.body.index("Pass ist gültig")
      end
    end

    context "as active tour guide" do
      it "shows tour guide information" do
        person.qualifications.create!(
          qualification_kind: qualification_kinds(:ski_leader),
          start_at: 1.month.ago
        )
        person.roles.create!(
          type: Group::SektionsTourenUndKurse::Tourenleiter.sti_name,
          group: groups(:matterhorn_touren_und_kurse)
        )

        visit "/passes/verify/#{pass.verify_token}"
        expect(page).to have_text "Aktive/r Tourenleiter/in"
      end
    end
  end
end
