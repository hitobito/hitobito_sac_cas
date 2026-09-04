#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event/participation_contact_datas/_fields.html.haml" do
  include FormatHelper

  let(:event) { events(:top_course) }
  let(:participation_contact_data) {
    Event::ParticipationContactData.new(event, people(:mitglied))
  }
  let(:policy_finder) { double(:policy_finder, acceptance_needed?: true, all: []) }
  let(:form_builder) {
    StandardFormBuilder.new(:participation_contact_data, participation_contact_data, view, {})
  }

  before do
    allow(form_builder).to receive(:fields_for).and_return([])
    allow(view).to receive_messages(f: form_builder, entry: participation_contact_data,
      phone_numbers: [], event: event)
    assign(:policy_finder, policy_finder)
  end

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  context "required fields" do
    [:email, :first_name, :last_name, :birthday, :zip_code, :town, :country].each do |field|
      it "#{field} is rendered with required mark" do
        expect(dom).to have_css "label.required",
          text: participation_contact_data.class.human_attribute_name(field)
      end
    end

    it "street is rendered with required mark" do
      expect(dom).to have_css "label.required", text: "Strasse"
    end
  end

  context "emergency contacts" do
    it "renders the four fields for courses" do
      expect(dom).to have_field "participation_contact_data[emergency_contact_1_name]"
      expect(dom).to have_field "participation_contact_data[emergency_contact_1_phone]"
      expect(dom).to have_field "participation_contact_data[emergency_contact_2_name]"
      expect(dom).to have_field "participation_contact_data[emergency_contact_2_phone]"
    end

    it "marks only first emergency contact as required" do
      expect(dom).to have_css "label.required", text: "Notfallkontakt 1 Name"
      expect(dom).to have_css "label.required", text: "Notfallkontakt 1 Telefonnummer"
      expect(dom).not_to have_css "label.required", text: "Notfallkontakt 2 Name"
      expect(dom).not_to have_css "label.required", text: "Notfallkontakt 2 Telefonnummer"
    end

    it "renders privacy notice" do
      expect(dom).to have_text "ausschliesslich für Notfälle"
      expect(dom).to have_link "AGB Ausbildung | Schweizer Alpen-Club SAC",
        href: "https://www.sac-cas.ch/de/meta/agb/ausbildung/"
    end

    it "hides emergency contacts for events that are neither course nor tour" do
      allow(view).to receive_messages(event: events(:top_event))

      expect(dom).not_to have_field "participation_contact_data[emergency_contact_1_name]"
      expect(dom).not_to have_text "ausschliesslich für Notfälle"
    end
  end
end
