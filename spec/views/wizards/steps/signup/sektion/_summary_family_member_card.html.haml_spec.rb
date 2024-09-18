#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "wizards/steps/signup/sektion/_summary_family_member_card.html.haml" do
  include FormatHelper

  let(:wizard) { Wizards::Signup::SektionWizard.new(group: groups(:bluemlisalp_neuanmeldungen_nv)) }
  let(:family) { Wizards::Steps::Signup::Sektion::FamilyFields.new(wizard) }
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }
  let(:attributes) {
    {
      first_name: "Larissa",
      last_name: "Muster",
      birthday: "01.01.2000",
      phone_number: "0791234567",
      email: "larissa.muster@hitobito.com"
    }
  }

  before do
    allow(view).to receive_messages(wizard: wizard)
    family.members_attributes = [
      [0, attributes]
    ]
    allow(view).to receive_messages(person: family.members.first)
  end


  it "renders summary card with all attributes" do
    expect(dom).to have_text "Erwachsene Person"
    expect(dom).to have_css('.fw-bold', text: "Larissa Muster")
    expect(dom).to have_text "Geburtstag"
    expect(dom).to have_text "01.01.2000"
    expect(dom).to have_text "Telefon (optional)"
    expect(dom).to have_text "0791234567"
    expect(dom).to have_text "E-Mail (optional)"
    expect(dom).to have_text "larissa.muster@hitobito.com"
  end

  it "does not render label when value is empty" do
    family.members.first.phone_number = ""
    expect(dom).not_to have_text "Telefon (optional)"
  end

  it "renders different title for children" do
    family.members.first.birthday = 10.years.ago
    expect(dom).not_to have_text "Erwachsene Person"
    expect(dom).to have_text "Kind"
  end
end
