# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "self_registration_abo_magazin", js: true do
  let(:group) { groups(:abo_die_alpen) }

  before do
    group.update!(self_registration_role_type: group.role_types.first)
    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
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

  def expect_shared_partial
    expect(page).to have_text "Preis pro Jahr"
  end

  def complete_main_person_form
    choose "männlich"
    fill_in "Vorname", with: "Max"
    fill_in "Nachname", with: "Muster"
    fill_in "wizards_signup_abo_magazin_wizard_person_fields_street", with: "Musterplatz"
    fill_in "wizards_signup_abo_magazin_wizard_person_fields_housenumber", with: "42"
    fill_in "Geburtsdatum", with: "01.01.1980"
    fill_in "Telefon", with: "+41 79 123 45 56"
    fill_in "wizards_signup_abo_magazin_wizard_person_fields_zip_code", with: "8000"
    fill_in "wizards_signup_abo_magazin_wizard_person_fields_town", with: "Zürich"
  end

  def complete_last_page(date: Date.tomorrow, submit: true)
    expect_active_step "Abo"
    expect_shared_partial
    fill_in "Ab Ausgabe", with: I18n.l(date)
    check "Ich habe die Statuten gelesen und stimme diesen zu"
    check "Ich habe die Datenschutzerklärung gelesen und stimme diesen zu"
    yield if block_given?
    if submit
      click_on "Registrieren"
      expect(page).to have_css "#error_explanation, #flash > .alert"
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
    expect_active_step "E-Mail"
    expect_shared_partial
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    click_on "Weiter"

    expect_active_step "Personendaten"
    expect_shared_partial
    complete_main_person_form
    click_on "Weiter"

    expect do
      complete_last_page
    end.to change { Person.count }.by(1)
  end

  it "renders date validation message" do
    visit group_self_registration_path(group_id: group.id)
    expect_active_step "E-Mail"
    expect_shared_partial
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    click_on "Weiter"

    expect_active_step "Personendaten"
    expect_shared_partial
    complete_main_person_form
    click_on "Weiter"

    expect do
      complete_last_page(date: Date.yesterday)
    end.not_to change { Person.count }
    expect(page).to have_text "Ab Ausgabe muss #{I18n.l(Time.zone.today)} oder danach sein"
  end

  it "subscribes to mailinglist" do
    visit group_self_registration_path(group_id: group.id)
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    click_on "Weiter"
    complete_main_person_form
    click_on "Weiter"

    expect do
      complete_last_page do
        check "Ich möchte einen Newsletter abonnieren"
      end
    end.to change { Person.count }.by(1)

    sign_in(people(:admin))
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
    click_on "Weiter"

    expect do
      complete_last_page do
        uncheck "Ich möchte einen Newsletter abonnieren"
      end
    end.to change { Person.count }.by(1)

    sign_in(people(:admin))
    person = Person.last
    visit group_person_subscriptions_path(group_id: person.primary_group_id, person_id: person.id)
    within("tr#mailing_list_#{mailing_lists(:newsletter).id}") do
      expect(page).to have_link("Anmelden")
    end
  end

  shared_examples "birthday validation" do |description, birthday, expected_step|
    it "handles #{description} person" do
      visit group_self_registration_path(group_id: group.id)
      fill_in "E-Mail", with: "max.muster@hitobito.example.com"
      click_on "Weiter"
      complete_main_person_form
      fill_in "Geburtsdatum", with: birthday
      click_on "Weiter"

      expect_active_step expected_step
      if Time.zone.today < birthday
        expect_validation_error "Person muss 0 Jahre oder älter sein"
      end
    end
  end

  it_behaves_like "birthday validation", "today", Time.zone.today, "Abo"
  it_behaves_like "birthday validation", "10 years ago", 10.years.ago, "Abo"
  it_behaves_like "birthday validation", "1 day from now", 1.day.from_now, "Personendaten"

  it "selects birthday via date picker", skip: "doesn't find select in ci" do
    travel_to Time.zone.local(2024, 1, 1)
    visit group_self_registration_path(group_id: group)
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    click_button "Weiter"
    fill_in "Geburtsdatum", with: "01.01.2024"
    find("label", text: "Geburtsdatum").click

    within "#ui-datepicker-div" do
      select "1924"
      find("[data-date=\"10\"]").click
    end

    expect(page).not_to have_css("option[value=\"1923\"]")
    expect(page).to have_field("Geburtsdatum", with: "10.01.1924")
  end
end
