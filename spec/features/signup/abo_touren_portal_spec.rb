# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "signup/abo_touren_portal_wizard" do
  let(:group) { Fabricate(Group::AboTourenPortal.sti_name, parent: groups(:abos)) }

  before do
    group.update!(self_registration_role_type: group.role_types.first)
    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
  end

  def complete_main_person_form
    choose "Mann"
    fill_in "Vorname", with: "Max"
    fill_in "Nachname", with: "Muster"
    fill_in "wizards_signup_abo_touren_portal_wizard_person_fields_street", with: "Musterplatz"
    fill_in "wizards_signup_abo_touren_portal_wizard_person_fields_housenumber", with: "42"
    fill_in "Geburtstag", with: "01.01.1980"
    fill_in "Telefon", with: "+41 79 123 45 56"
    fill_in "wizards_signup_abo_touren_portal_wizard_person_fields_zip_code", with: "8000"
    fill_in "wizards_signup_abo_touren_portal_wizard_person_fields_town", with: "Zürich"
    check "Ich habe die Statuten gelesen und stimme diesen zu"
    check "Ich habe die Datenschutzerklärung gelesen und stimme diesen zu"
  end

  def expect_active_step(step_name)
    expect(page)
      .to have_css(".step-headers li.active", text: step_name),
        "expected step '#{step_name}' to be active, but step '#{find(".step-headers li.active", wait: 0).text}' is active"
  end

  def expect_validation_error(message)
    within(".alert#error_explanation") do
      expect(page).to have_content(message)
    end
  end

  it "validates email address" do
    allow(Truemail).to receive(:valid?).with("max.muster@hitobito.example.com").and_return(false)
    visit group_self_registration_path(group_id: group.id)
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    click_on "Weiter"
    expect_active_step("E-Mail")
    expect_validation_error("E-Mail ist nicht gültig")
  end

  it "creates person" do
    visit group_self_registration_path(group_id: group.id)
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    expect(page).to have_text "Preis pro Jahr"
    click_on "Weiter"
    expect(page).to have_text "Preis pro Jahr"
    complete_main_person_form
    expect do
      click_on "Registrieren"
      expect(page).to have_css "#error_explanation, #flash > .alert"
    end.to change { Person.count }.by(1)
  end

  it "subscribes to mailinglist" do
    visit group_self_registration_path(group_id: group.id)
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    click_on "Weiter"
    complete_main_person_form
    check "Ich möchte einen Newsletter abonnieren"
    expect do
      click_on "Registrieren"
      expect(page).to have_css "#error_explanation, #flash > .alert"
    end.to change { Person.count }.by(1)

    sign_in(people(:admin))
    visit root_path

    person = Person.last
    visit group_person_subscriptions_path(group_id: person.primary_group_id, person_id: person.id)
    within("tr#mailing_list_#{mailing_lists(:newsletter).id}") do
      expect(page).to have_link("Abmelden")
    end
  end

  it "opts out of mailinglist" do
    visit group_self_registration_path(group_id: group.id)
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    click_on "Weiter"
    complete_main_person_form
    uncheck "Ich möchte einen Newsletter abonnieren"
    expect do
      click_on "Registrieren"
      expect(page).to have_css "#error_explanation, #flash > .alert"
    end.to change { Person.count }.by(1)

    sign_in(people(:admin))
    person = Person.last
    visit group_person_subscriptions_path(group_id: person.primary_group_id, person_id: person.id)
    within("tr#mailing_list_#{mailing_lists(:newsletter).id}") do
      expect(page).to have_link("Anmelden")
    end
  end

  it "validates that person is old enough" do
    visit group_self_registration_path(group_id: group.id)
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    click_on "Weiter"
    complete_main_person_form
    fill_in "Geburtstag", with: 17.years.ago.to_date
    expect do
      click_on "Registrieren"
      expect(page).to have_text "Person muss 18 Jahre oder älter sein"
    end.not_to change { Person.count }
  end
end
