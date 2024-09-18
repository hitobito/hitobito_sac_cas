#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "wizards/steps/signup/sektion/_summary_person_card.html.haml" do
  include FormatHelper

  let(:wizard) { Wizards::Signup::SektionWizard.new(group: groups(:bluemlisalp_neuanmeldungen_nv)) }
  let(:person) { Wizards::Steps::Signup::Sektion::PersonFields.new(wizard) }
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }
  let(:attributes) {
    {
      first_name: "Max",
      last_name: "Muster",
      address_care_of: "2.Stock",
      street: "Musterplatz",
      housenumber: "23",
      town: "Zurich",
      zip_code: "8000",
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

  it "renders summary card with all attributes" do
    expect(dom).to have_text "Kontaktperson"
    expect(dom).to have_css(".fw-bold", text: "Max Muster")
    expect(dom).to have_text "zusätzliche Adresszeile"
    expect(dom).to have_text "2.Stock"
    expect(dom).to have_text "Strasse und Nr."
    expect(dom).to have_text "Musterplatz 23"
    expect(dom).to have_text "PLZ/Ort"
    expect(dom).to have_text "8000 Zurich"
    expect(dom).to have_text "Geburtstag"
    expect(dom).to have_text "01.01.2000"
    expect(dom).to have_text "Telefon"
    expect(dom).to have_text "0791234567"
    expect(dom).to have_text "Haupt-E-Mail"
    expect(dom).to have_text "max.muster@hitobito.com"
  end

  it "does not render label when value is empty" do
    person.phone_number = ""
    expect(dom).not_to have_text "Telefon"
  end
end
