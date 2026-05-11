# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Dropdown::Events::Tours::State do
  include LayoutHelper
  include FormatHelper
  include UtilityHelper

  subject(:dom) { Capybara::Node::Simple.new(dropdown.to_s) }

  let(:dropdown) { described_class.new(self, event.decorate) }
  let(:params) { {group_id: event.groups.first.id, id: event.id} }
  let(:event) { events(:section_tour) }

  before do
    allow(view).to receive_messages(entry: event, params:)
  end

  def print
    puts Nokogiri::XML(dropdown.to_s, &:noblanks)
  end

  it "renders review popover" do
    event.state = :draft
    event.approvals.create!(approved: true)

    expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", text: "Zur Freigabe weiterleiten"

    content = Capybara::Node::Simple.new(dom.find_link("Zur Freigabe weiterleiten")["data-bs-content"])
    expect(content).to have_button "Bestehende Freigaben zurücksetzen", name: "button", value: "destroy"
    expect(content).to have_button "Bestehende Freigaben beibehalten", name: "button", value: "keep"
  end

  it "renders publish popover" do
    event.state = :approved
    expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", text: "Publizieren"

    content = Capybara::Node::Simple.new(dom.find_link("Publizieren")["data-bs-content"])
    expect(content).to have_field "Interne Bemerkungen"
    expect(content).to have_text "Interessierte Sektionsmitglieder"
    expect(content).to have_text "Zuständige(s) Freigabe-Komitee(s)"
    expect(content).to have_text "Leitungsperson(en)"
  end

  it "renders back to published popover" do
    event.state = :ready
    expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", text: "Zurück zu Publiziert"

    content = Capybara::Node::Simple.new(dom.find_link("Zurück zu Publiziert")["data-bs-content"])
    expect(content).to have_field "Interne Bemerkungen"
    expect(content).to have_text "Zuständige(s) Freigabe-Komitee(s)"
    expect(content).to have_text "Leitungsperson(en)"
  end

  it "renders ready popover" do
    event.state = :published

    expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", text: "Vorbereitung abgeschlossen"

    content = Capybara::Node::Simple.new(dom.find_link("Vorbereitung abgeschlossen")["data-bs-content"])
    expect(content).to have_field "Interne Bemerkungen"
    expect(content).to have_text "Bestätigte Teilnehmer:innen"
    expect(content).to have_text "Unbestätigte Teilnehmer:innen"
    expect(content).to have_text "Leitungsperson(en)"
  end

  it "renders back to ready popover" do
    event.state = :closed

    expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", text: "Zurück zu Vorbereitung abgeschlossen"

    content = Capybara::Node::Simple.new(dom.find_link("Zurück zu Vorbereitung abgeschlossen")["data-bs-content"])
    expect(content).to have_field "Interne Bemerkungen"
    expect(content).to have_text "Zuständige(s) Freigabe-Komitee(s)"
    expect(content).to have_text "Leitungsperson(en)"
  end

  it "renders close popover" do
    event.state = :ready
    expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", text: "Abschliessen"

    content = Capybara::Node::Simple.new(dom.find_link("Abschliessen")["data-bs-content"])
    expect(content).to have_field "Interne Bemerkungen"
    expect(content).to have_text "Teilgenommene Teilnehmer:innen"
    expect(content).to have_text "Leitungsperson(en)"
  end

  it "renders cancel popover" do
    event.state = :ready
    expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", text: "Absagen"

    content = Capybara::Node::Simple.new(dom.find_link("Absagen")["data-bs-content"])
    expect(content).to have_field "Interne Bemerkungen"
    expect(content).to have_field "Absagegrund"
    expect(content).to have_text "Zuständige(s) Freigabe-Komitee(s)"
    expect(content).to have_text "Teilnehmer:innen"
    expect(content).to have_text "Leitungsperson(en)"
  end

  it "renders back to draft popover" do
    event.state = :approved
    expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", text: "Zurück zu Entwurf"

    content = Capybara::Node::Simple.new(dom.find_link("Zurück zu Entwurf")["data-bs-content"])
    expect(content).to have_field "Interne Bemerkungen"
    expect(content).to have_text "Zuständige(s) Freigabe-Komitee(s)"
    expect(content).to have_text "Leitungsperson(en)"
  end

  it "renders back to approved popover" do
    event.state = :published
    expect(dom).to have_css "a.dropdown-item[data-bs-toggle]", text: "Zurück zu Freigegeben"

    content = Capybara::Node::Simple.new(dom.find_link("Zurück zu Freigegeben")["data-bs-content"])
    expect(content).to have_field "Interne Bemerkungen"
    expect(content).to have_text "Zuständige(s) Freigabe-Komitee(s)"
    expect(content).to have_text "Leitungsperson(en)"
  end
end
