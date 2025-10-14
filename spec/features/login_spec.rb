# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe :login, js: true do
  let(:password) { "cNb@X7fTdiU4sWCMNos3gJmQV_d9e9" }
  let(:person) { people(:mitglied).tap { |p| p.update!(password: password) } }

  around do |example|
    old_attrs = Person.devise_login_id_attrs.dup
    example.run
    Person.devise_login_id_attrs = old_attrs
  end

  after { logout }

  before do
    visit new_person_session_path
    expect(page).to have_field "Haupt‑E‑Mail / Mitglied‑Nr"
    expect(page).to have_field "Passwort"
  end

  it "has correct login field label" do
    expect(page).to have_selector('label[for="person_login_identity"]',
      text: "Haupt‑E‑Mail / Mitglied‑Nr")
  end

  it "allows login with email" do
    fill_in "Haupt‑E‑Mail / Mitglied‑Nr", with: person.email
    fill_in "Passwort", with: password
    click_button "Anmelden"

    expect(page).to have_link "Abmelden"
    expect(page).to have_selector(".content-header h1", text: person.full_name)
  end

  it "allows login with membership_number" do
    fill_in "Haupt‑E‑Mail / Mitglied‑Nr", with: person.membership_number
    fill_in "Passwort", with: password
    click_button "Anmelden"

    expect(page).to have_link "Abmelden"
    expect(page).to have_selector(".content-header h1", text: person.full_name)
  end

  describe "WSO2 legacy password" do
    let(:legacy_password) { "new long test password" }
    let(:salt) { "Salty Salt" }

    before do
      person.update!(
        encrypted_password: nil,
        wso2_legacy_password_hash: generate_wso2_legacy_password_hash(legacy_password, salt),
        wso2_legacy_password_salt: salt
      )
    end

    it "allows login with legacy password" do
      expect(person.valid_password?(legacy_password)).to be_truthy
      fill_in "Haupt‑E‑Mail / Mitglied‑Nr", with: person.email
      fill_in "Passwort", with: legacy_password
      click_button "Anmelden"

      expect(page).to have_link "Abmelden"
      expect(page).to have_selector(".content-header h1", text: person.full_name)

      expect(person.reload.wso2_legacy_password_hash).to be_nil
      expect(person.reload.wso2_legacy_password_salt).to be_nil
      expect(person.reload.encrypted_password).to be_present
    end
  end
end
