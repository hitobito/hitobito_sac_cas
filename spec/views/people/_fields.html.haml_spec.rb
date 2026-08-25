#  Copyright (c) 2012-2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "people/_fields.html.haml" do
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }
  let(:person) { people(:mitglied) }
  let(:form_builder) {
    StandardFormBuilder.new(:person, person, view, {
      builder: StandardFormBuilder
    })
  }

  before do
    allow(view).to receive(:entry).and_return(person)
    allow(controller).to receive(:current_user).and_return(person)
    allow(view).to receive(:f).and_return(form_builder)
  end

  describe "correspondence" do
    let(:digital_input) { dom.find("input#person_correspondence_digital").native }

    it "is disabled if email is blank" do
      person.email = nil
      expect(digital_input.attributes).to have_key("disabled")
    end

    it "is disabled if email is not yet confirmed" do
      person.update(email: "test@example.com", confirmed_at: nil)
      expect(digital_input.attributes).to have_key("disabled")
    end

    it "is not disabled if email is present" do
      person.update!(confirmed_at: 1.week.ago)
      expect(digital_input.attributes).not_to have_key("disabled")
    end
  end

  describe "emergency contacts" do
    it "renders the four fields" do
      expect(dom).to have_field "person[emergency_contact_1_name]"
      expect(dom).to have_field "person[emergency_contact_1_phone]"
      expect(dom).to have_field "person[emergency_contact_2_name]"
      expect(dom).to have_field "person[emergency_contact_2_phone]"
    end

    it "renders privacy notice" do
      expect(dom).to have_text "ausschliesslich für Notfälle"
      expect(dom).to have_link "AGB Ausbildung | Schweizer Alpen-Club SAC",
        href: "https://www.sac-cas.ch/de/meta/agb/ausbildung/"
    end

    it "fills fields with stored values" do
      person.update!(
        emergency_contact_1_name: "Tina #{person.last_name}",
        emergency_contact_1_phone: "079 123 45 67"
      )

      expect(dom).to have_field "person[emergency_contact_1_name]", with: "Tina #{person.last_name}"
      expect(dom).to have_field "person[emergency_contact_1_phone]", with: "079 123 45 67"
    end
  end
end
