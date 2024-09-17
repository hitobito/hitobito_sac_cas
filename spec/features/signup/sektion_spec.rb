# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "signup/sektion", js: true do
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:self_registration_role) { group.decorate.allowed_roles_for_self_registration.first }
  let(:person) { Person.find_by(email: "max.muster@hitobito.example.com") }

  before do
    group.self_registration_role_type = self_registration_role
    group.save!

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

  def assert_aside(*birthdays)
    expect(page).to have_css("aside h2", text: "Fragen zur Mitgliedschaft?")
    expect(page).to have_css("aside#fees h2", text: "Beiträge in der Sektion #{group.layer_group.name}")
    birthdays.each do |birthday|
      expect(page).to have_css("aside#fees li", text: birthday)
    end
  end

  def assert_step(step_name)
    expect(page).to have_css(".step-headers li.active", text: step_name),
      "expected step '#{step_name}' to be active, but step '#{find(".step-headers li.active", wait: 0).text}' is active"
  end

  def complete_main_person_form
    assert_step "Haupt-E-Mail"
    assert_aside
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    click_on "Weiter"
    assert_step "Personendaten"
    choose "Mann"
    fill_in "Vorname", with: "Max"
    fill_in "Nachname", with: "Muster"
    fill_in "wizards_signup_sektion_wizard_person_fields_street", with: "Musterplatz"
    fill_in "wizards_signup_sektion_wizard_person_fields_housenumber", with: "42"
    fill_in "Geburtstag", with: "01.01.1980"
    fill_in "Telefon", with: "+41 79 123 45 56"
    fill_in "wizards_signup_sektion_wizard_person_fields_zip_code", with: "8000"
    fill_in "wizards_signup_sektion_wizard_person_fields_town", with: "Zürich"
    find(:label, "Land").click
    find(:option, text: "Vereinigte Staaten").click
    expect(page).not_to have_field("Newsletter")
    assert_aside("01.01.1980")
    yield if block_given?
    click_on "Weiter"
  end

  def complete_household_form
    assert_step "Familienmitglieder"
    click_on "Eintrag hinzufügen"

    within "#members_fields .fields:nth-child(1)" do
      fill_in "Vorname", with: "Maxine"
      fill_in "Nachname", with: "Muster"
      fill_in "Geburtstag", with: "01.01.1981"
      fill_in "E-Mail (optional)", with: "maxine.muster@hitobito.example.com"
      choose "Frau"
    end
    yield if block_given?
    click_on "Weiter als Familienmitgliedschaft", match: :first
  end

  def complete_last_page(with_adult_consent: true, submit: true)
    assert_step "Zusatzdaten"
    expect(page).to have_button("Registrieren"), "expected to be on last page"
    if with_adult_consent
      check "Ich bestätige, dass ich mindestens 18 Jahre alt bin oder das Einverständnis meiner Erziehungsberechtigten habe"
    end
    check "Ich habe die Statuten gelesen und stimme diesen zu"
    check "Ich habe das Beitragsreglement gelesen und stimme diesen zu"
    check "Ich habe die Datenschutzerklärung gelesen und stimme diesen zu"

    yield if block_given?
    if submit
      click_on "Registrieren"
      expect(page).to have_css "#error_explanation, #flash > .alert"
    end
  end

  def click_on_breadcrumb(link_text)
    within(".step-headers") { click_on link_text }
  end

  def format_date(time_or_date)
    time_or_date.strftime("%d.%m.%Y")
  end

  it "validates email address" do
    allow(Truemail).to receive(:valid?).with("max.muster@hitobito.example.com").and_return(false)
    visit group_self_registration_path(group_id: group.id)
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    click_on "Weiter"
    expect_active_step("E-Mail")
    expect_validation_error("E-Mail ist nicht gültig")
  end

  describe "existing email" do
    let(:person) { people(:admin) }
    let(:password) { "really_b4dPassw0rD" }

    it "redirects to login page" do
      person.update!(password: password, password_confirmation: password)

      visit group_self_registration_path(group_id: group)
      fill_in "Mail", with: person.email
      click_on "Weiter"
      expect(page).to have_css ".alert-success",
        text: "Es existiert bereits ein Login für diese E-Mail."
      expect(page).to have_css "h1", text: "Anmelden"
      expect(page).to have_field "Haupt‑E‑Mail / Mitglied‑Nr", with: person.email
      fill_in "Passwort", with: password
      click_on "Anmelden"
      # In https://github.com/hitobito/hitobito_sac_cas/pull/860 we removed the
      # customized SAC self-inscription. There was some logic in
      # app/models/self_inscription.rb to find the correct group to get the
      # title from.
      pending("The title currently doesn't get set correctly")
      expect(page).to have_css "h1", text: "Registrierung zu SAC Blüemlisalp"
      expect(page).to have_button "Beitreten"
    end
  end

  describe "main_person" do
    it "self registers and creates new person" do
      visit group_self_registration_path(group_id: group)
      expect(page).to have_css("h2", text: "Fragen zur Mitgliedschaft?")
      complete_main_person_form
      click_on "Weiter als Einzelmitglied", match: :first

      expect do
        complete_last_page
      end.to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
        .and change { ActionMailer::Base.deliveries.count }.by(1)
      expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")

      expect(person).to be_present
      expect(person.first_name).to eq "Max"
      expect(person.last_name).to eq "Muster"
      expect(person.address).to eq "Musterplatz 42"
      expect(person.zip_code).to eq "8000"
      expect(person.town).to eq "Zürich"
      expect(person.country).to eq "US"
      expect(person.birthday).to eq Date.new(1980, 1, 1)

      person.confirm # confirm email

      person.password = person.password_confirmation = "really_b4dPassw0rD"
      person.save!

      fill_in "Haupt‑E‑Mail / Mitglied‑Nr", with: "max.muster@hitobito.example.com"
      fill_in "Passwort", with: "really_b4dPassw0rD"

      click_button "Anmelden"

      expect(person.roles.map(&:type)).to eq([self_registration_role.to_s])
      expect(person.roles.find { |r| r.type == self_registration_role.to_s }.delete_on).to be_nil
      expect(current_path).to eq("/de#{group_person_path(group_id: group, id: person)}.html")
    end

    it "can autocomplete address" do
      Address.create!(
        street_short: "Belpstrasse",
        street_short_old: "Belpstrasse",
        street_long: "Belpstrasse",
        street_long_old: "Belpstrasse",
        town: "Bern",
        state: "BE",
        zip_code: 3007,
        numbers: ["36", "37", "38", "40", "41", "5a", "5b", "6A", "6B"]
      )
      visit group_self_registration_path(group_id: group)
      fill_in "E-Mail", with: "max.muster@hitobito.example.com"
      click_on "Weiter"
      fill_in "wizards_signup_sektion_wizard_person_fields_street", with: "Belp"
      dropdown = find('ul[role="listbox"]')
      expect(dropdown).to have_content("Belpstrasse 3007 Bern")

      find('ul[role="listbox"] li[role="option"]', text: "Belpstrasse 3007 Bern", match: :first)
        .click

      expect(page).to have_field("wizards_signup_sektion_wizard_person_fields_zip_code", with: "3007")
      expect(page).to have_field("wizards_signup_sektion_wizard_person_fields_town", with: "Bern")
      expect(page).to have_field("wizards_signup_sektion_wizard_person_fields_street", with: "Belpstrasse")
    end

    it "validates required fields" do
      visit group_self_registration_path(group_id: group)
      fill_in "E-Mail", with: "max.muster@hitobito.example.com"
      click_on "Weiter"
      click_on "Weiter", match: :first

      expect(page).to have_selector("#error_explanation") # wait for the error message to appear
      expect(find_field("Vorname")[:class]).to match(/\bis-invalid\b/)
      expect(find_field("Nachname")[:class]).to match(/\bis-invalid\b/)
      expect(find_field("Geburtstag")[:class]).to match(/\bis-invalid\b/)
      expect(find("#wizards_signup_sektion_wizard_person_fields_street")[:class]).to match(/\bis-invalid\b/)
      expect(find_field("PLZ/Ort")[:class]).to match(/\bis-invalid\b/)
      expect(find("#wizards_signup_sektion_wizard_person_fields_town")[:class]).to match(/\bis-invalid\b/)
      expect(find_field("Telefon")[:class]).to match(/\bis-invalid\b/)
    end
  end

  describe "household" do
    before do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      expect(page).to have_content "Indem du weitere Personen hinzufügst, wählst du eine"
    end

    it "validates household required fields" do
      click_on "Eintrag hinzufügen"
      click_on "Weiter als Familienmitgliedschaft", match: :first

      expect(page).to have_selector("#error_explanation") # wait for the error message to appear
      within "#members_fields .fields:nth-child(1)" do
        expect(find_field("Vorname")[:class]).to match(/\bis-invalid\b/)
        expect(find_field("Nachname")[:class]).to match(/\bis-invalid\b/)
        expect(find_field("Geburtstag")[:class]).to match(/\bis-invalid\b/)

        expect(find_field("E-Mail (optional)")[:class]).not_to match(/\bis-invalid\b/)
        expect(find_field("Telefon (optional)")[:class]).not_to match(/\bis-invalid\b/)
      end
    end

    it "can create several people in same household" do
      click_on "Eintrag hinzufügen"

      within "#members_fields .fields:nth-child(1)" do
        fill_in "Vorname", with: "Maxine"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtstag", with: "01.01.1981"
        fill_in "E-Mail (optional)", with: "maxine.muster@hitobito.example.com"
        choose "Frau"
      end
      assert_aside("01.01.1980", "01.01.1981")
      click_on "Eintrag hinzufügen"

      within "#members_fields .fields:nth-child(2)" do
        fill_in "Vorname", with: "Maxi"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtstag", with: format_date(15.years.ago)
        fill_in "E-Mail (optional)", with: "maxi.muster@hitobito.example.com"
        choose "Andere"
      end

      assert_aside("01.01.1980", "01.01.1981", format_date(15.years.ago))
      click_button("Weiter als Familienmitgliedschaft", match: :first)

      expect do
        complete_last_page
        expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine " \
          "E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")
      end.to change { Person.count }.by(3)
        .and change { Role.count }.by(3)
        .and change { ActionMailer::Base.deliveries.count }.by(3)

      people = Person.where(last_name: "Muster")
      expect(people).to have(3).items
      expect(Person.where(household_key: people.first.household_key)).to have(3).items
    end

    it "validates we only can have one additional adult in household" do
      click_on "Eintrag hinzufügen"

      within "#members_fields .fields:nth-child(1)" do
        fill_in "Vorname", with: "Maxine"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtstag", with: "01.01.1981"
        fill_in "E-Mail (optional)", with: "maxine.muster@hitobito.example.com"
        choose "Frau"
      end
      assert_aside("01.01.1980", "01.01.1981")

      click_on "Eintrag hinzufügen"
      within "#members_fields .fields:nth-child(2)" do
        fill_in "Vorname", with: "Maxi"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtstag", with: "01.01.1978"
        fill_in "E-Mail (optional)", with: "maxi.muster@hitobito.example.com"
        choose "Andere"
      end
      assert_aside("01.01.1980", "01.01.1981", "01.01.1978")

      click_on "Weiter als Familienmitgliedschaft", match: :first

      within("#error_explanation") do
        expect(page).to have_content "In einer Familienmitgliedschaft sind maximal 2 Erwachsene inbegriffen."
      end
    end

    it "validates we can not add youth in household" do
      click_on "Eintrag hinzufügen"

      within "#members_fields .fields:nth-child(1)" do
        fill_in "Vorname", with: "Maxine"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtstag", with: format_date(20.years.ago)
      end
      click_on "Weiter als Familienmitgliedschaft", match: :first

      within("#error_explanation") do
        expect(page).to have_content "Jugendliche im Alter von 18 bis 21 Jahre können nicht in einer Familienmitgliedschaft aufgenommen werden"
      end
    end

    it "can have many children in household" do
      anchor_date = 15.years.ago.to_date
      7.times.each do |i|
        click_on "Eintrag hinzufügen"
        within "#members_fields .fields:nth-child(#{i + 1})" do
          fill_in "Vorname", with: "Kind #{i + 1}"
          fill_in "Nachname", with: "Muster"
          fill_in "Geburtstag", with: format_date(anchor_date + i.years)
        end
      end
      click_on "Weiter als Familienmitgliedschaft", match: :first
      expect(page).to have_button "Registrieren"
      expect(page).to have_no_selector "#error_explanation"
    end

    it "can add and remove housemate" do
      click_on "Eintrag hinzufügen"

      within "#members_fields .fields:nth-child(1)" do
        fill_in "Vorname", with: "Maxine"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtstag", with: "01.01.1981"
        fill_in "E-Mail (optional)", with: "maxine.muster@hitobito.example.com"
        choose "Frau"
      end
      assert_aside("01.01.1980", "01.01.1981")

      click_on "Eintrag hinzufügen"
      within "#members_fields .fields:nth-child(2)" do
        fill_in "Vorname", with: "Maxi"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtstag", with: format_date(15.years.ago)
        fill_in "E-Mail (optional)", with: "maxi.muster@hitobito.example.com"
        choose "Andere"
      end
      assert_aside("01.01.1980", "01.01.1981", format_date(15.years.ago))

      within "#members_fields .fields:nth-child(1)" do
        click_on "Entfernen"
      end
      assert_aside("01.01.1980", format_date(15.years.ago))
      click_on "Weiter als Familienmitgliedschaft", match: :first

      expect do
        complete_last_page
        expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine " \
          "E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")
      end.to change { Person.count }.by(2)
      people = Person.where(last_name: "Muster")
      expect(people).to have(2).items
      expect(people.pluck(:first_name)).to match_array(%w[Max Maxi])
    end

    it "validates emails within household" do
      click_on "Eintrag hinzufügen"

      fill_in "Vorname", with: "Maxine"
      fill_in "Nachname", with: "Muster"
      fill_in "Geburtstag", with: "01.01.1981"
      fill_in "E-Mail (optional)", with: "max.muster@hitobito.example.com"
      choose "Frau"
      click_on "Weiter als Familienmitgliedschaft", match: :first
      expect(page).to have_content "E-Mail (optional) ist bereits vergeben"
      expect(page).to have_button "Weiter als Familienmitgliedschaft", match: :first
    end

    it "validates phone_number of housemate" do
      click_on "Eintrag hinzufügen"

      fill_in "Vorname", with: "Maxine"
      fill_in "Nachname", with: "Muster"
      fill_in "Geburtstag", with: "01.01.1981"
      fill_in "E-Mail (optional)", with: "max.muster@hitobito.example.com"
      fill_in "Telefon (optional)", with: "123"
      choose "Frau"
      click_on "Weiter als Familienmitgliedschaft", match: :first
      within "#members_fields .fields:nth-child(1)" do
        expect(page).to have_content "Telefon (optional) ist nicht gültig"
      end
    end

    it "can continue with incomplete removed housemate" do
      click_on "Eintrag hinzufügen"
      fill_in "Vorname", with: "Maxine"
      fill_in "Nachname", with: "Muster"
      within "#members_fields .fields:nth-child(1)" do
        click_on "Entfernen"
      end
      click_on "Weiter als Einzelmitglied", match: :first
      expect(page).to have_button "Registrieren"
    end

    context "bluemlisalp_neuanmeldungen_sektion" do
      let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }

      it "validates birthday is valid" do
        skip("Sometimes does not work on CI. Nobody knows why, so just skip it") if ci?
        click_on "Eintrag hinzufügen"

        fill_in "Vorname", with: "Maxi"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtstag", with: format_date(1.day.ago)
        fill_in "E-Mail (optional)", with: "maxi.muster@hitobito.example.com"
        choose "Frau"
        click_on "Weiter als Familienmitgliedschaft", match: :first
        expect(page).to have_content "Person muss 6 Jahre oder älter sein"
      end
    end

    context "button groups" do
      it "has only bottom button toolbar without hosemate" do
        expect(page).to have_selector(".btn-toolbar.bottom")
        expect(page).to have_no_selector(".btn-toolbar.top")
      end

      it "has both button groups with housemate" do
        click_on("Eintrag hinzufügen")

        expect(page).to have_selector(".btn-toolbar.bottom")
        expect(page).to have_selector(".btn-toolbar.top")
      end

      it "has both button groups with housemate when navigating back" do
        click_on("Eintrag hinzufügen")
        fill_in "Vorname", with: "Max"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtstag", with: "01.01.1980"
        within(".btn-toolbar.top") do
          click_on("Weiter als Familienmitgliedschaft")
        end
        assert_step "Zusatzdaten"
        click_on("Zurück")

        expect(page).to have_selector(".btn-toolbar.bottom")
        expect(page).to have_selector(".btn-toolbar.top")
      end
    end
  end

  describe "main person household age validations" do
    let(:twenty_years_ago) { format_date(20.years.ago) }

    it "skips household when person is too young" do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form do
        fill_in "Geburtstag", with: twenty_years_ago
      end
      assert_step("Zusatzdaten")
      expect(page).not_to have_link "Familienmitglieder"
    end

    it "clears household members when changing main person birthday too young" do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form

      click_on "Eintrag hinzufügen"
      within "#members_fields .fields:nth-child(1)" do
        fill_in "Vorname", with: "Maxine"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtstag", with: "01.01.1981"
        fill_in "E-Mail (optional)", with: "maxine.muster@hitobito.example.com"
        choose "Frau"
      end

      click_on "Zurück", match: :first
      fill_in "Geburtstag", with: twenty_years_ago
      click_on "Weiter"
      assert_aside(twenty_years_ago)
      expect do
        complete_last_page
        expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine " \
          "E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")
      end.to change { Person.count }.by(1)
    end
  end

  describe "supplements" do
    let(:root) { groups(:root) }
    let(:list) { Fabricate(:mailing_list, group: root) }

    before do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on "Weiter als Einzelmitglied", match: :first
    end

    it "creates excluding subscription if newsletter is unchecked" do
      root.update!(sac_newsletter_mailing_list_id: list.id)
      uncheck "Ich möchte einen Newsletter abonnieren"
      complete_last_page
      expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine " \
        "E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")
      expect(person.subscriptions.excluded).to have(1).items
    end

    it "persists self_registration_reason" do
      SelfRegistrationReason.create!(text: "naja")
      reason = SelfRegistrationReason.create!(text: "soso")
      expect(page).to have_css("label", text: "Eintrittsgrund")
      choose "soso"
      complete_last_page
      expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine " \
        "E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")
      expect(person.self_registration_reason).to eq reason
    end

    context "future role" do
      around do |example|
        travel_to(Date.new(2023, 3, 1)) do
          example.run
        end
      end

      it "creates future role for main person" do
        expect(page).to have_css("label", text: "Eintrittsdatum per")
        choose "01. Juli"
        expect do
          complete_last_page
          expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine " \
            "E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")
        end.to change { FutureRole.count }.by(1)
        expect(FutureRole.first.convert_on).to eq Date.new(2023, 7, 1)
      end
    end
  end

  describe "with adult consent" do
    before do
      group.update!(self_registration_require_adult_consent: true)
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on "Weiter als Einzelmitglied", match: :first
    end

    it "cannot complete without accepting adult consent" do
      expect { complete_last_page(with_adult_consent: false) }.not_to change { Person.count }
      expect(page).to have_text "Einverständniserklärung der Erziehungsberechtigten muss akzeptiert werden"
    end

    it "can complete when accepting adult consent" do
      expect do
        complete_last_page(with_adult_consent: true)
        expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine " \
          "E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")
      end.to change { Person.count }.by(1)
    end
  end

  describe "with section privacy policy" do
    before do
      file = Rails.root.join("spec", "fixtures", "files", "images", "logo.png")
      image = ActiveStorage::Blob.create_and_upload!(io: File.open(file, "rb"),
        filename: "logo.png",
        content_type: "image/png").signed_id
      group.layer_group.update!(privacy_policy: image)
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on "Weiter als Einzelmitglied", match: :first
    end

    it "fails if section policy is not accepted" do
      expect do
        complete_last_page
      end.not_to change { Person.count }
      expect(page).to have_text "Sektionsstatuten muss akzeptiert werden"
    end

    it "sets privacy policy accepted" do
      expect do
        complete_last_page do
          check "Ich habe die Sektionsstatuten gelesen und stimme diesen zu"
        end
        expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine " \
          "E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")
      end.to change { Person.count }.by(1)
      person = Person.find_by(email: "max.muster@hitobito.example.com")
      expect(person.privacy_policy_accepted).to eq true
    end
  end

  describe "document links" do
    it "should open privacy policy in new tab" do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_on "Weiter als Einzelmitglied", match: :first

      expect(page).to have_link("Statuten", target: "_blank")
      expect(page).to have_link("Beitragsreglement", target: "_blank")
      expect(page).to have_link("Datenschutzerklärung", target: "_blank")
    end
  end

  describe "wizard stepping navigation" do
    context "for family registration" do
      it "can go back and forth" do
        skip("Does not work on CI. Nobody knows why, so just skip it") if ci?

        visit group_self_registration_path(group_id: group)
        complete_main_person_form
        complete_household_form
        assert_step "Zusatzdaten"

        click_on "Zurück", match: :first
        assert_step "Familienmitglieder"
        click_on "Weiter", match: :first
        assert_step "Zusatzdaten"
        click_on "Zurück", match: :first
        click_on "Zurück", match: :first
        assert_step "Personendaten"
        click_on "Weiter", match: :first
        assert_step "Familienmitglieder"

        click_on "Zurück", match: :first
        click_on "Zurück", match: :first
        assert_step "Haupt-E-Mail"
        click_on "Weiter", match: :first
        assert_step "Personendaten"
        click_on "Weiter", match: :first
        assert_step "Familienmitglieder"

        click_on "Zurück", match: :first
        click_on "Weiter", match: :first
        click_on "Weiter als Familienmitgliedschaft", match: :first
        assert_step "Zusatzdaten"
      end
    end

    context "for single person registration" do
      before do
        visit group_self_registration_path(group_id: group)
        complete_main_person_form
        click_on "Weiter als Einzelmitglied", match: :first
        assert_step "Zusatzdaten"
      end

      it "can go back and forth" do
        click_on "Zurück", match: :first
        assert_step "Familienmitglieder"
        click_on "Weiter", match: :first
        assert_step "Zusatzdaten"
        click_on "Zurück", match: :first
        click_on "Zurück", match: :first
        assert_step "Personendaten"
        click_on "Weiter", match: :first
        assert_step "Familienmitglieder"
        click_on "Zurück", match: :first
        click_on "Zurück", match: :first
        assert_step "Haupt-E-Mail"
        click_on "Weiter", match: :first
        assert_step "Personendaten"
        click_on "Weiter", match: :first
        assert_step "Familienmitglieder"
        click_on "Zurück", match: :first
        click_on "Weiter", match: :first
        click_on "Weiter als Einzelmitglied", match: :first
        assert_step "Zusatzdaten"
      end
    end

    context "for youth person registration" do
      before do
        visit group_self_registration_path(group_id: group)
        complete_main_person_form do
          fill_in "Geburtstag", with: format_date(15.years.ago)
        end
        assert_step("Zusatzdaten")
      end

      it "can go back and forth" do
        click_on "Zurück", match: :first
        assert_step "Personendaten"
        click_on "Weiter", match: :first
        assert_step "Zusatzdaten"
        click_on "Zurück", match: :first
        click_on "Zurück", match: :first
        assert_step "Haupt-E-Mail"
        click_on "Weiter", match: :first
        click_on "Weiter", match: :first
        assert_step "Zusatzdaten"
      end
    end
  end
end
