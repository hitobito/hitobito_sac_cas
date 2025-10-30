# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Dropdown::PeopleExport do
  include Rails.application.routes.url_helpers
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:user) { people(:admin) }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:params) { {controller: "people", action: "index", group_id: group.id} }
  let(:options) { {} }
  let(:dropdown) do
    Dropdown::PeopleExport.new(self, user, params, options)
  end

  subject { Capybara.string(dropdown.to_s) }

  def menu = subject.find(".btn-group > ul.dropdown-menu")

  def top_menu_entries = menu.all("> li > a").map(&:text)

  def submenu_entries(name)
    menu.all("> li > a:contains('#{name}') ~ ul > li > a").map(&:text)
  end

  context "people" do
    let(:parent) { group }

    it "renders dropdown for people" do
      is_expected.to have_content "Export"

      expect(top_menu_entries).to match_array ["CSV", "Excel", "vCard", "PDF"]
      expect(submenu_entries("CSV")).to match_array([
        "Spaltenauswahl",
        "Adressliste",
        "Für den elektronischen Versand (E-Mail)",
        "Für den postalischen Versand"
      ])
      expect(submenu_entries("PDF")).to match_array []
    end
  end

  context "event participants" do
    let(:event) { events(:section_tour) }
    let(:params) do
      {controller: "event/participations", group_id: groups(:bluemlisalp).id, event_id: event.id}
    end
    let(:options) { {details: true} }

    def entry
      Event::Participation.new(event: event)
    end

    it "renders dropdown" do
      is_expected.to have_content "Export"

      expect(top_menu_entries).to match_array %w[CSV Excel vCard PDF]
      expect(submenu_entries("CSV")).to match_array([
        "Adressliste",
        "Alle Angaben",
        "Für den elektronischen Versand (E-Mail)",
        "Für den postalischen Versand",
        "NDS-Lager",
        "Spaltenauswahl"
      ])
      expect(submenu_entries("PDF")).to match_array []
    end

    context "course" do
      let(:event) { events(:top_course) }
      let(:params) do
        {controller: "event/participations", group_id: groups(:root).id, event_id: event.id}
      end

      it "renders dropdown with pdf options" do
        is_expected.to have_content "Export"

        expect(top_menu_entries).to match_array %w[CSV Excel vCard PDF]
        expect(submenu_entries("CSV")).to match_array(
          ["Adressliste",
            "Adressliste und Kursdaten",
            "Alle Angaben",
            "Für den elektronischen Versand (E-Mail)",
            "Für den postalischen Versand",
            "NDS-Kurs",
            "NDS-Lager",
            "SLRG-Kurs",
            "Spaltenauswahl"]
        )
        expect(submenu_entries("PDF")).to match_array([
          "Adressliste",
          "Liste für Teilnehmende",
          "Liste für Kurskader"
        ])
      end

      context "as participant" do
        let(:user) { people(:mitglied) }
        let(:options) { {details: false} }

        it "renders dropdown with pdf options" do
          is_expected.to have_content "Export"

          expect(top_menu_entries).to match_array %w[CSV Excel vCard PDF]
          expect(submenu_entries("CSV")).to match_array(
            ["Adressliste",
              "Für den elektronischen Versand (E-Mail)",
              "Für den postalischen Versand",
              "Spaltenauswahl"]
          )
          expect(submenu_entries("PDF")).to match_array([])
        end
      end
    end
  end
end
