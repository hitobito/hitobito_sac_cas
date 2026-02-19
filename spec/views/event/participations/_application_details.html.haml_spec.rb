#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event/participations/_application_details.html.haml" do
  include FormatHelper

  let(:participation) { event_participations(:top_mitglied) }
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }
  let(:membership_attributes_container) { dom.find("dl:nth-of-type(1)") }
  let(:event_attrributes_container) { dom.find("dl:nth-of-type(2)") }

  before do
    allow(view).to receive_messages(entry: participation.decorate)
    assign(:event, event.decorate)
  end

  def expect_attribute_row(container, index, label, expected_value = nil)
    row = container.find("div:nth-of-type(#{index})")

    expect(row).to have_css("dt", text: label)
    expect(row).to have_css("dd", text: expected_value.to_s) if expected_value.present?
  end

  context "course" do
    let(:event) { events(:top_course) }

    before do
      participation.update!(price: 20, price_category: "price_regular", invoice_state: :payed)
      participation.person.update!(correspondence: "digital")
    end

    it "does render all relevant attributes" do
      expect_attribute_row(membership_attributes_container, 1, "Personennummer", participation.participant_id)
      expect_attribute_row(membership_attributes_container, 2, "SAC-Mitglied", "ja")
      expect_attribute_row(membership_attributes_container, 3, "Anzahl Mitglieder-Jahre",
        participation.membership_years)

      expect_attribute_row(event_attrributes_container, 1, "Anmeldedatum")
      expect_attribute_row(event_attrributes_container, 2, "Status", "Bestätigt")
      expect_attribute_row(event_attrributes_container, 3, "Effektive Tage", "")
      expect_attribute_row(event_attrributes_container, 4, "Preis", "CHF 20.00 (Normalpreis)")
      expect_attribute_row(event_attrributes_container, 5, "Rechnung", "Bezahlt")
      expect_attribute_row(event_attrributes_container, 6, "Rechnungsstellung", "Digital")
    end

    it "does render relevant membership attributes for participation without mitglied role" do
      roles(:mitglied).destroy!

      expect_attribute_row(membership_attributes_container, 1, "Personennummer", participation.participant_id)
      expect_attribute_row(membership_attributes_container, 2, "SAC-Mitglied", "nein")
      expect(dom).not_to have_text "Anzahl Mitglieder-Jahre"
    end
  end

  context "tour" do
    let(:event) { events(:section_tour) }

    it "does render all relevant attributes" do
      expect_attribute_row(membership_attributes_container, 1, "Personennummer", participation.participant_id)
      expect_attribute_row(membership_attributes_container, 2, "SAC-Mitglied", "ja")
      expect_attribute_row(membership_attributes_container, 3, "Anzahl Mitglieder-Jahre",
        participation.membership_years)

      expect_attribute_row(event_attrributes_container, 1, "Anmeldedatum")
      expect_attribute_row(event_attrributes_container, 2, "Status", "Bestätigt")
      expect(dom).not_to have_text "Effektive Tage"
      expect(dom).not_to have_text "Preis"
      expect(dom).not_to have_text "Rechnung"
      expect(dom).not_to have_text "Rechnungsstellung"
    end
  end

  context "event" do
    let(:event) { events(:top_event) }

    it "does render all relevant attributes" do
      expect_attribute_row(membership_attributes_container, 1, "Personennummer", participation.participant_id)
      expect_attribute_row(membership_attributes_container, 2, "SAC-Mitglied", "ja")
      expect_attribute_row(membership_attributes_container, 3, "Anzahl Mitglieder-Jahre",
        participation.membership_years)

      expect_attribute_row(event_attrributes_container, 1, "Anmeldedatum")
      expect_attribute_row(event_attrributes_container, 2, "Status", "Bestätigt")
      expect(dom).not_to have_text "Effektive Tage"
      expect(dom).not_to have_text "Preis"
      expect(dom).not_to have_text "Rechnung"
      expect(dom).not_to have_text "Rechnungsstellung"
    end
  end
end
