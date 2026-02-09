# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Dropdown::Events::State do
  include LayoutHelper
  include FormatHelper
  include UtilityHelper
  let(:event) { events(:top_course) }

  subject(:dom) { Capybara::Node::Simple.new(dropdown.to_s) }

  let(:dropdown) { described_class.new(self, event.decorate) }

  let(:params) { {group_id: event.groups.first.id, id: event.id} }

  before do
    allow(view).to receive_messages(entry: event, params:)
  end

  def print
    puts Nokogiri::XML(dropdown.to_s, &:noblanks)
  end

  describe "created state" do
    before { event.state = :created }

    it "renders dropdown with single button that triggers email skipping popover" do
      expect(dom).to have_link "Entwurf", class: "dropdown-toggle", href: "#"
      expect(dom).to have_css "a.dropdown-item", count: 1
      expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", text: "Publizieren"
      popover = Capybara::Node::Simple.new(dom.find_link("Publizieren")["data-bs-content"])
      expect(popover).to have_button "E-Mails verschicken", name: "button"
      expect(popover).to have_button "Keine E-Mails verschicken", name: "skip_emails", value: "true"
    end
  end

  describe "assignment closed state" do
    before { event.state = :assignment_closed }

    it "renders 3 dropdown items two of which have popovers" do
      expect(dom).to have_link "Zuteilung abgeschlossen", class: "dropdown-toggle", href: "#"
      expect(dom).to have_css "a.dropdown-item", count: 3
      expect(dom).to have_css "a.dropdown-item:not([data-bs-toggle])", count: 1
      expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", count: 2
    end

    it "renders cancel popover" do
      expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", text: "Absagen"
      content = Capybara::Node::Simple.new(dom.find_link("Absagen")["data-bs-content"])
      expect(content).not_to have_button "E-Mails verschicken"
      expect(content).to have_text "Sagt den Kurs Tourenleiter/in 1 Sommer (10) ab"
    end

    it "renders email skipping popover only for one of two state transitions" do
      expect(dom).to have_css "a.dropdown-item:not([data-bs-toggle])",
        text: "Zurück zur abgeschlossenen Anmeldung"
      expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", text: "Bereit zur Durchführung"

      # rubocop:todo Layout/LineLength
      content = Capybara::Node::Simple.new(dom.find_link("Bereit zur Durchführung")["data-bs-content"])
      # rubocop:enable Layout/LineLength
      expect(content).to have_button "E-Mails verschicken", name: "button"
      expect(content).to have_button "Keine E-Mails verschicken", name: "skip_emails", value: "true"
    end
  end

  describe "dropdown false state" do
    let(:event) { events(:section_tour) }

    before do
      event.state = :review
    end

    it "does not render state with option dropdown false" do
      expect(dom).to have_link "In Freigabe", class: "dropdown-toggle", href: "#"
      expect(dom).not_to have_css "a.dropdown-item", text: "Selbst freigeben"
    end
  end
end
