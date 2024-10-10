#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "wizards/steps/signup/abo_magazin/_person_info_table.html.haml" do
  include FormatHelper

  let(:wizard) { Wizards::Signup::AboMagazinWizard.new(group: groups(:bluemlisalp_neuanmeldungen_nv)) }
  let(:person) { Wizards::Steps::Signup::AboMagazin::PersonFields.new(wizard) }
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }
  let(:attributes) {
    {
      gender: "m",
      first_name: "Max",
      last_name: "Muster",
      address_care_of: "2.Stock",
      street: "Musterplatz",
      housenumber: "23",
      postbox: "Postfach 23",
      town: "Zurich",
      zip_code: "8000",
      country: "CH",
      birthday: "01.01.2000",
      phone_number: "0791234567"
    }
  }

  before do
    allow(view).to receive_messages(wizard: wizard)
    allow(view).to receive_messages(person: person)
    person.attributes = attributes
    wizard.main_email_field.email = "max.muster@hitobito.com"
  end

  it "renders table with all information" do
    expect(dom).to have_text "Geschlecht"
    expect(dom).to have_text "männlich"
    expect(dom).to have_text "Vorname"
    expect(dom).to have_text "Max"
    expect(dom).to have_text "Nachname"
    expect(dom).to have_text "Muster"
    expect(dom).to have_text "E-Mail"
    expect(dom).to have_text "max.muster@hitobito.com"
    expect(dom).to have_text "Geburtsdatum"
    expect(dom).to have_text "01.01.2000"
    expect(dom).to have_text "Strasse und Nr."
    expect(dom).to have_text "Musterplatz 23"
    expect(dom).to have_text "Adresszusatz"
    expect(dom).to have_text "2.Stock"
    expect(dom).to have_text "Postfach"
    expect(dom).to have_text "Postfach 23"
    expect(dom).to have_text "PLZ"
    expect(dom).to have_text "8000"
    expect(dom).to have_text "Ort"
    expect(dom).to have_text "Zurich"
    expect(dom).to have_text "Land"
    expect(dom).to have_text "Schweiz"
  end
end
