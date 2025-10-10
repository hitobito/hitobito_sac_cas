# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "signup/sektion", :js do
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:self_registration_role) { group.decorate.allowed_roles_for_self_registration.first }
  let(:person) { Person.find_by(email: "max.muster@hitobito.example.com") }

  before do
    group.self_registration_role_type = self_registration_role
    group.save!

    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
  end

  def expect_active_step(step_name)
    expect(page).to have_css(".step-headers li.active", text: step_name),
      "expected step '#{step_name}' to be active, but step '#{find(".step-headers li.active", wait: 0).text}' is active"
  end

  def expect_validation_error(message)
    within(".alert#error_explanation") do
      expect(page).to have_content(message)
    end
  end

  def assert_aside(beitragskategorie: :all)
    kind = case beitragskategorie
    when :all then "Beitragskategorien"
    when :adult then "Einzelmitgliedschaft"
    when :youth then "Jugendmitgliedschaft"
    when :family then "Familienmitgliedschaft"
    end
    expect(page).to have_css("aside h2", text: "#{kind} #{group.layer_group.name}")
    expect(page).to have_css("aside h2", text: "Fragen zur Mitgliedschaft?")
  end

  def assert_step(step_name)
    expect(page).to have_css(".step-headers li.active", text: step_name),
      "expected step '#{step_name}' to be active, but step '#{find(".step-headers li.active", wait: 0).text}' is active"
  end

  # force step rerender because the buttons don't always show up immediately
  def force_rerender
    click_link "Zurück", match: :first
    click_button "Weiter", match: :first
  end

  def complete_main_person_form
    assert_step "E-Mail"
    assert_aside
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    click_button "Weiter"
    assert_step "Personendaten"
    choose "männlich"
    fill_in "Vorname", with: "Max"
    fill_in "Nachname", with: "Muster"
    fill_in "wizards_signup_sektion_wizard_person_fields_street", with: "Musterplatz"
    fill_in "wizards_signup_sektion_wizard_person_fields_housenumber", with: "42"
    fill_in "Geburtsdatum", with: "01.01.1980"
    fill_in "Telefon", with: "+41 79 123 45 56"
    fill_in "wizards_signup_sektion_wizard_person_fields_zip_code", with: "40202"
    fill_in "wizards_signup_sektion_wizard_person_fields_town", with: "Zürich"
    find(:label, "Land").click
    find(:option, text: "Vereinigte Staaten").click
    expect(page).not_to have_field("Newsletter")
    assert_aside(beitragskategorie: :adult)
    yield if block_given?
    click_button "Weiter"
  end

  def complete_household_form
    assert_step "Familienmitglieder"
    click_link "Weiteres Familienmitglied hinzufügen"

    within "#members_fields .fields:first-child" do
      fill_in "Vorname", with: "Maxine"
      fill_in "Nachname", with: "Muster"
      fill_in "Geburtsdatum", with: "01.01.1981"
      fill_in "E-Mail", with: "maxine.muster@hitobito.example.com"
      fill_in "Telefon", with: "0791234567"
      choose "weiblich"
    end
    yield if block_given?
    force_rerender
    click_button "Weiter als Familienmitgliedschaft", match: :first
  end

  def complete_last_page(submit: true)
    assert_step "Zusammenfassung"
    expect(page).to have_button("Mitgliedschaft beantragen"), "expected to be on last page"
    check "Ich habe die Statuten gelesen und stimme diesen zu"
    check "Ich habe das Beitragsreglement gelesen und stimme diesem zu"
    check "Ich habe die Datenschutzerklärung gelesen und stimme dieser zu"

    yield if block_given?
    if submit
      click_on "Mitgliedschaft beantragen"
      expect(page).to have_css "#error_explanation, #flash > .alert"
    end
  end

  def format_date(time_or_date)
    time_or_date.strftime("%d.%m.%Y")
  end

  it "validates email address" do
    allow(Truemail).to receive(:valid?).with("max.muster@hitobito.example.com").and_return(false)
    visit group_self_registration_path(group_id: group.id)
    fill_in "E-Mail", with: "max.muster@hitobito.example.com"
    click_button "Weiter"
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
      click_button "Weiter"
      expect(page).to have_css ".alert-success",
        text: "Es existiert bereits ein Login für diese E-Mail."
      expect(page).to have_css "h1", text: "Anmelden"
      expect(page).to have_field "Haupt‑E‑Mail / Mitglied‑Nr", with: person.email
      fill_in "Passwort", with: password
      click_button "Anmelden"
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
      click_button "Weiter als Einzelmitglied"
      click_button "Weiter"

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
      expect(person.zip_code).to eq "40202"
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
      expect(person.roles.find { |r| r.type == self_registration_role.to_s }.end_on).to be_nil
      expect(current_path).to eq("#{group_person_path(group_id: group, id: person)}.html")
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
      click_button "Weiter"
      fill_in "wizards_signup_sektion_wizard_person_fields_street", with: "Belp"
      dropdown = find('ul[role="listbox"]')
      expect(dropdown).to have_content("Belpstrasse 3007 Bern")

      find('ul[role="listbox"] li[role="option"]', text: "Belpstrasse 3007 Bern").click

      expect(page).to have_field("wizards_signup_sektion_wizard_person_fields_zip_code", with: "3007")
      expect(page).to have_field("wizards_signup_sektion_wizard_person_fields_town", with: "Bern")
      expect(page).to have_field("wizards_signup_sektion_wizard_person_fields_street", with: "Belpstrasse")
    end

    it "validates required fields" do
      visit group_self_registration_path(group_id: group)
      fill_in "E-Mail", with: "max.muster@hitobito.example.com"
      click_button "Weiter"
      click_button "Weiter"

      expect(page).to have_selector("#error_explanation") # wait for the error message to appear
      expect(find_field("Vorname")[:class]).to match(/\bis-invalid\b/)
      expect(find_field("Nachname")[:class]).to match(/\bis-invalid\b/)
      expect(find_field("Geburtsdatum")[:class]).to match(/\bis-invalid\b/)
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
      click_link "Weiteres Familienmitglied hinzufügen"
      force_rerender
      click_button "Weiter als Familienmitgliedschaft", match: :first

      expect(page).to have_selector("#error_explanation") # wait for the error message to appear
      within "#members_fields .fields:first-child" do
        expect(find_field("Vorname")[:class]).to match(/\bis-invalid\b/)
        expect(find_field("Nachname")[:class]).to match(/\bis-invalid\b/)
        expect(find_field("Geburtsdatum")[:class]).to match(/\bis-invalid\b/)

        expect(find_field("E-Mail")[:class]).not_to match(/\bis-invalid\b/)
        expect(find_field("Telefon")[:class]).not_to match(/\bis-invalid\b/)
      end
    end

    it "switches back to Einzelmitgliedschaft when adding and removing member" do
      click_link "Weiteres Familienmitglied hinzufügen"
      within "#members_fields .fields:first-child" do
        fill_in "Geburtsdatum", with: "01.01.1981"
        fill_in "Vorname", with: "Maxine"
      end
      force_rerender
      expect(page).to have_button "Weiter als Familienmitgliedschaft"
      assert_aside(beitragskategorie: :family)
      within "#members_fields .fields:first-child" do
        click_link "Entfernen"
      end
      force_rerender
      expect(page).to have_button "Weiter als Einzelmitglied"
      assert_aside(beitragskategorie: :einzel)
    end

    it "can create several people in same household" do
      click_link "Weiteres Familienmitglied hinzufügen"

      within "#members_fields .fields:first-child" do
        fill_in "Vorname", with: "Maxine"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtsdatum", with: "01.01.1981"
        fill_in "E-Mail", with: "maxine.muster@hitobito.example.com"
        fill_in "Telefon", with: "0791234567"
        choose "weiblich"
      end
      assert_aside(beitragskategorie: :family)
      click_link "Weiteres Familienmitglied hinzufügen"

      within "#members_fields .fields:nth-child(2)" do
        fill_in "Vorname", with: "Maxi"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtsdatum", with: format_date(15.years.ago)
        fill_in "E-Mail", with: "maxi.muster@hitobito.example.com"
        choose "divers"
      end

      assert_aside(beitragskategorie: :family)
      force_rerender
      click_button "Weiter als Familienmitgliedschaft", match: :first
      click_button "Weiter", match: :first

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
      click_link "Weiteres Familienmitglied hinzufügen"

      within "#members_fields .fields:first-child" do
        fill_in "Vorname", with: "Maxine"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtsdatum", with: "01.01.1981"
        fill_in "E-Mail", with: "maxine.muster@hitobito.example.com"
        fill_in "Telefon", with: "0791234567"
        choose "weiblich"
      end
      assert_aside(beitragskategorie: :family)

      click_link "Weiteres Familienmitglied hinzufügen"
      within "#members_fields .fields:nth-child(2)" do
        fill_in "Vorname", with: "Maxi"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtsdatum", with: "01.01.1978"
        fill_in "E-Mail", with: "maxine.muster@hitobito.example.com"
        fill_in "Telefon", with: "0791234567"
        choose "divers"
      end
      assert_aside(beitragskategorie: :family)

      force_rerender
      click_button "Weiter als Familienmitgliedschaft", match: :first

      within("#error_explanation") do
        expect(page).to have_content "In einer Familienmitgliedschaft sind maximal 2 Erwachsene inbegriffen."
      end
    end

    it "validates we can not add youth in household" do
      click_link "Weiteres Familienmitglied hinzufügen"

      within "#members_fields .fields:first-child" do
        fill_in "Vorname", with: "Maxine"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtsdatum", with: format_date(20.years.ago)
      end
      force_rerender
      click_button "Weiter als Familienmitgliedschaft", match: :first

      within("#error_explanation") do
        expect(page).to have_content "Jugendliche im Alter von 18 bis 22 Jahren können nicht in einer Familienmitgliedschaft aufgenommen werden"
      end
    end

    it "can have many children in household" do
      anchor_date = 15.years.ago.to_date
      7.times.each do |i|
        click_link "Weiteres Familienmitglied hinzufügen"
        within "#members_fields .fields:nth-child(#{i + 1})" do
          fill_in "Vorname", with: "Kind #{i + 1}"
          fill_in "Nachname", with: "Muster"
          fill_in "Geburtsdatum", with: format_date(anchor_date + i.years)
          choose "divers"
        end
      end
      force_rerender
      click_button "Weiter als Familienmitgliedschaft", match: :first
      click_button "Weiter", match: :first
      expect(page).to have_button "Mitgliedschaft beantragen"
      expect(page).to have_no_selector "#error_explanation"
    end

    it "can add and remove housemate" do
      click_link "Weiteres Familienmitglied hinzufügen"

      within "#members_fields .fields:first-child" do
        fill_in "Vorname", with: "Maxine"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtsdatum", with: "01.01.1981"
        fill_in "E-Mail", with: "maxine.muster@hitobito.example.com"
        fill_in "Telefon", with: "0791234567"
        choose "weiblich"
      end
      assert_aside(beitragskategorie: :family)

      click_link "Weiteres Familienmitglied hinzufügen"
      within "#members_fields .fields:nth-child(2)" do
        fill_in "Vorname", with: "Maxi"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtsdatum", with: format_date(15.years.ago)
        fill_in "E-Mail", with: "maxi.muster@hitobito.example.com"
        choose "divers"
      end
      assert_aside(beitragskategorie: :family)
      within "#members_fields .fields:first-child" do
        click_link "Entfernen"
      end
      assert_aside(beitragskategorie: :family)
      force_rerender
      click_button "Weiter als Familienmitgliedschaft", match: :first
      click_button "Weiter", match: :first

      expect do
        complete_last_page
        expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine " \
          "E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")
      end.to change { Person.count }.by(2)
      people = Person.where(last_name: "Muster")
      expect(people).to have(2).items
      expect(people.pluck(:first_name)).to match_array(%w[Max Maxi])
    end

    it "validates emails dynamically for household input" do
      click_link "Weiteres Familienmitglied hinzufügen"
      fill_in "E-Mail", with: "e.hillary@hitobito.example.com"
      fill_in "Vorname", with: "Maxi"
      field = find_field("E-Mail")
      expect(page).to have_css(".is-invalid")
      expect(page).to have_css "##{field[:id]}.is-invalid"
      expect(page).to have_css ".invalid-feedback", text: "Die E-Mail Adresse ist bereits registriert " \
        "und somit kann diese Person der Familie nicht hinzugefügt werden. Bitte wende dich an den Mitgliederdienst, " \
        "um deine Familie zu erfassen: 031 370 18 18, mv@sac-cas.ch"
      fill_in "E-Mail", with: "eddy.hillary@hitobito.example.com"
      fill_in "Vorname", with: "Maxi"
      expect(page).not_to have_css ".invalid-feedback"
      expect(find_field("E-Mail")[:class]).not_to match(/\bis-invalid\b/)
    end

    it "does not treat empty email as invalid" do
      click_link "Weiteres Familienmitglied hinzufügen"
      fill_in "Geburtsdatum", with: "01.01.2000"

      force_rerender
      click_button "Weiter als Familienmitgliedschaft", match: :first
      within "#members_fields .fields:first-child" do
        expect(page).to have_content "E-Mail muss ausgefüllt werden"
        expect(page).not_to have_content "Die E-Mail Adresse ist bereits registriert"
      end
    end

    it "validates emails within household on form submit" do
      click_link "Weiteres Familienmitglied hinzufügen"

      fill_in "Vorname", with: "Maxine"
      fill_in "Nachname", with: "Muster"
      fill_in "Geburtsdatum", with: "01.01.1981"
      fill_in "E-Mail", with: "max.muster@hitobito.example.com"
      fill_in "Telefon", with: "0791234567"
      choose "weiblich"
      force_rerender
      click_button "Weiter als Familienmitgliedschaft", match: :first
      expect(page).to have_content "E-Mail ist bereits vergeben"
      expect(page).to have_button "Weiter als Familienmitgliedschaft"
    end

    it "validates phone_number of housemate" do
      click_link "Weiteres Familienmitglied hinzufügen"

      fill_in "Vorname", with: "Maxine"
      fill_in "Nachname", with: "Muster"
      fill_in "Geburtsdatum", with: "01.01.1981"
      fill_in "E-Mail", with: "maxine.muster@hitobito.example.com"
      fill_in "Telefon", with: "123"
      choose "weiblich"
      force_rerender
      click_button "Weiter als Familienmitgliedschaft", match: :first
      within "#members_fields .fields:first-child" do
        expect(page).to have_content "Telefon ist nicht gültig"
      end
    end

    it "can continue with incomplete removed housemate" do
      click_link "Weiteres Familienmitglied hinzufügen"
      fill_in "Vorname", with: "Maxine"
      fill_in "Nachname", with: "Muster"
      within "#members_fields .fields:first-child" do
        click_link "Entfernen"
      end
      click_button "Weiter als Einzelmitglied"
      click_button "Weiter"
      expect(page).to have_button "Mitgliedschaft beantragen"
    end

    context "bluemlisalp_neuanmeldungen_sektion" do
      let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }

      it "validates birthday is valid" do
        click_link "Weiteres Familienmitglied hinzufügen"

        fill_in "Vorname", with: "Maxi"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtsdatum", with: format_date(1.day.ago)
        fill_in "E-Mail", with: "maxine.muster@hitobito.example.com"
        fill_in "Telefon", with: "0791234567"
        choose "weiblich"
        force_rerender
        click_button "Weiter als Familienmitgliedschaft", match: :first
        expect(page).to have_content "Person muss 6 Jahre oder älter sein"
      end
    end

    context "button groups" do
      it "has only bottom button toolbar without housemate" do
        expect(page).to have_selector(".btn-toolbar.bottom")
        expect(page).to have_no_selector(".btn-toolbar.top")
      end

      it "has both button groups with housemate" do
        click_link "Weiteres Familienmitglied hinzufügen"
        force_rerender

        expect(page).to have_selector(".btn-toolbar.bottom")
      end

      it "has both button groups with housemate when navigating back" do
        click_link "Weiteres Familienmitglied hinzufügen"
        choose "männlich"
        fill_in "Vorname", with: "Max"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtsdatum", with: "01.01.1980"
        fill_in "E-Mail", with: "maxine.muster@hitobito.example.com"
        fill_in "Telefon", with: "0791234567"
        force_rerender
        click_button "Weiter als Familienmitgliedschaft", match: :first
        assert_step "Zusatzdaten"
        click_link "Zurück"

        expect(page).to have_selector(".btn-toolbar.bottom")
      end
    end
  end

  describe "main person household age validations" do
    let(:twenty_years_ago) { format_date(20.years.ago) }

    it "skips household when person is too young" do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form do
        fill_in "Geburtsdatum", with: twenty_years_ago
      end
      assert_step("Zusatzdaten")
      expect(page).not_to have_link "Familienmitglieder"
    end

    it "clears household members when changing main person birthday too young" do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form

      click_link "Weiteres Familienmitglied hinzufügen"
      within "#members_fields .fields:first-child" do
        fill_in "Vorname", with: "Maxine"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtsdatum", with: "01.01.1981"
        fill_in "E-Mail", with: "maxine.muster@hitobito.example.com"
        fill_in "Telefon", with: "0791234567"
        choose "weiblich"
      end

      click_link "Zurück", match: :first
      fill_in "Geburtsdatum", with: twenty_years_ago
      click_button "Weiter"
      assert_aside(beitragskategorie: :youth)
      click_button "Weiter"
      expect do
        complete_last_page
        expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine " \
          "E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")
      end.to change { Person.count }.by(1)
    end
  end

  describe "supplements" do
    let(:root) { groups(:root) }

    before do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
      click_button "Weiter als Einzelmitglied"
    end

    it "creates including subscription if newsletter is checked" do
      click_button "Weiter"
      check "Ich möchte den SAC-Newsletter abonnieren."
      complete_last_page
      expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine " \
        "E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")
      expect(person.subscriptions.excluded).to have(0).items
      expect(person.subscriptions.included).to have(1).items
    end

    it "persists self_registration_reason" do
      SelfRegistrationReason.create!(text: "naja")
      reason = SelfRegistrationReason.create!(text: "soso")
      expect(page).to have_css("label", text: "Eintrittsgrund")
      choose "soso"
      click_button "Weiter"
      complete_last_page
      expect(page).to have_text("Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine " \
        "E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.")
      expect(person.self_registration_reason).to eq reason
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
      click_button "Weiter als Einzelmitglied"
      click_button "Weiter"
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
      click_button "Weiter als Einzelmitglied"

      expect(page).to have_link("Statuten", target: "_blank")
      expect(page).to have_link("Beitragsreglement", target: "_blank")
      expect(page).to have_link("Datenschutzerklärung", target: "_blank")
    end
  end

  describe "summary page" do
    before do
      visit group_self_registration_path(group_id: group)
      complete_main_person_form
    end

    it "should display person and entry fee card" do
      click_button "Weiter als Einzelmitglied"
      click_button "Weiter"

      expect(find_all(".well").count).to eq(1)
      expect(page).to have_css(".well", text: "Kontaktperson")
      expect(page).not_to have_css("h2", text: "Familienmitglieder")
    end

    it "should display summary card for each family member" do
      click_link "Weiteres Familienmitglied hinzufügen"
      within "#members_fields .fields:first-child" do
        fill_in "Vorname", with: "Maxine"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtsdatum", with: "01.01.1981"
        fill_in "E-Mail", with: "maxine.muster@hitobito.example.com"
        fill_in "Telefon", with: "0791234567"
        choose "weiblich"
      end
      click_link "Weiteres Familienmitglied hinzufügen"
      within "#members_fields .fields:nth-child(2)" do
        fill_in "Vorname", with: "Larissa"
        fill_in "Nachname", with: "Muster"
        fill_in "Geburtsdatum", with: format_date(15.years.ago)
        fill_in "E-Mail", with: "larissa.muster@hitobito.example.com"
        choose "divers"
      end

      force_rerender
      click_button "Weiter als Familienmitgliedschaft", match: :first
      click_button "Weiter", match: :first
      assert_step "Zusammenfassung"

      expect(find_all(".well").count).to eq(3)
      expect(page).to have_css(".well", text: "Erwachsene Person")
      expect(page).to have_css(".well", text: "Kind")
    end
  end

  describe "wizard stepping navigation" do
    context "for family registration" do
      it "can go back and forth" do
        visit group_self_registration_path(group_id: group)
        complete_main_person_form
        complete_household_form
        assert_step "Zusatzdaten"

        click_link "Zurück", match: :first
        assert_step "Familienmitglieder"
        click_button "Weiter", match: :first
        assert_step "Zusatzdaten"
        click_link "Zurück", match: :first
        click_link "Zurück", match: :first
        assert_step "Personendaten"
        click_button "Weiter", match: :first
        assert_step "Familienmitglieder"

        click_link "Zurück", match: :first
        click_link "Zurück", match: :first
        assert_step "E-Mail"
        click_button "Weiter", match: :first
        assert_step "Personendaten"
        click_button "Weiter", match: :first
        assert_step "Familienmitglieder"

        click_link "Zurück", match: :first
        click_button "Weiter", match: :first
        click_button "Weiter als Familienmitgliedschaft", match: :first
        assert_step "Zusatzdaten"
      end
    end

    context "for single person registration" do
      before do
        visit group_self_registration_path(group_id: group)
        complete_main_person_form
        click_button "Weiter als Einzelmitglied"
        assert_step "Zusatzdaten"
      end

      it "can go back and forth" do
        click_link "Zurück"
        assert_step "Familienmitglieder"
        click_button "Weiter"
        assert_step "Zusatzdaten"
        click_link "Zurück"
        click_link "Zurück"
        assert_step "Personendaten"
        click_button "Weiter"
        assert_step "Familienmitglieder"
        click_link "Zurück"
        click_link "Zurück"
        assert_step "E-Mail"
        click_button "Weiter"
        assert_step "Personendaten"
        click_button "Weiter"
        assert_step "Familienmitglieder"
        click_link "Zurück"
        click_button "Weiter"
        click_button "Weiter als Einzelmitglied"
        assert_step "Zusatzdaten"
      end
    end

    context "for youth person registration" do
      before do
        visit group_self_registration_path(group_id: group)
        complete_main_person_form do
          fill_in "Geburtsdatum", with: format_date(15.years.ago)
        end
        assert_step("Zusatzdaten")
      end

      it "can go back and forth" do
        click_link "Zurück"
        assert_step "Personendaten"
        click_button "Weiter"
        assert_step "Zusatzdaten"
        click_link "Zurück"
        click_link "Zurück"
        assert_step "E-Mail"
        click_button "Weiter"
        click_button "Weiter"
        assert_step "Zusatzdaten"
      end
    end
  end

  describe "abroad_fees" do
    before do
      travel_to(Date.new(2024, 6, 1))
      visit group_self_registration_path(group_id: group)
      fill_in "E-Mail", with: "max.muster@hitobito.example.com"
      click_button "Weiter"

      fill_in "Geburtsdatum", with: "01.01.1980"
    end

    it "displays abroad_fees in aside for person not living in switzerland" do
      find(:label, "Land").click
      find(:option, text: "Vereinigte Staaten").click
      expect(page).to have_text("+ Gebühren Ausland")
      expect(page).to have_text("CHF 23.00")
    end

    it "doesnt display abroad_fees in aside for person from switzerland" do
      find(:label, "Land").click
      find_all(:option, text: "Schweiz").first.click
      expect(page).not_to have_text("+ Gebühren Ausland")
      expect(page).not_to have_text("CHF 23.00")
    end

    it "doesnt display abroad_fees in aside for person from liechtenstein" do
      find(:label, "Land").click
      find_all(:option, text: "Liechtenstein").first.click
      expect(page).not_to have_text("+ Gebühren Ausland")
      expect(page).not_to have_text("CHF 23.00")
    end
  end

  describe "self registration for logged in users" do
    let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }

    before do
      sign_in(person)
    end

    context "SAC member" do
      let(:person) { people(:mitglied) }

      it "redirects to memberships tab with a flash message" do
        visit group_self_registration_path(group_id: group)
        expect(page).to have_content("Du besitzt bereits eine SAC-Mitgliedschaft. Wenn du diese anpassen möchtest, kontaktiere bitte die SAC-Geschäftsstelle.")
      end
    end

    context "SAC subscriber" do
      let(:person) { people(:abonnent) }

      it "contains the users data pre-filled" do
        visit group_self_registration_path(group_id: group)
        expect(page).to have_field("Vorname", with: person.first_name)
        expect(page).to have_field("Nachname", with: person.last_name)
        fill_in "Vorname", with: "Test"
        fill_in "Telefon", with: "+41 79 123 45 56"
        find(:label, "Land").click
        fill_in "wizards_signup_sektion_wizard_person_fields_zip_code", with: "40202"
        find(:option, text: "Vereinigte Staaten").click
        click_button "Weiter"
        click_button "Weiter als Einzelmitglied"
        click_button "Weiter"
        complete_last_page
        expect(page).to have_content "Deine Anmeldung wurde erfolgreich gespeichert"
        expect(person.reload.first_name).to eq "Test"
      end
    end
  end
end
