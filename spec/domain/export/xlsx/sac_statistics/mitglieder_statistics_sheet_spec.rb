# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require_relative "row_collector"

describe Export::Xlsx::MitgliederStatistics::Sheet do
  let(:range) { Date.new(2024, 1, 1)..Date.new(2024, 12, 31) }

  def create_role(type, group = groups(:bluemlisalp_mitglieder), **attrs)
    Fabricate("Group::SektionsMitglieder::#{type}", group:, **attrs)
  end

  context "as within sac statistics" do
    let(:xlsx) { RowCollector.new }
    let(:sheet) { described_class.new(xlsx, range, relevant_role_types: SacCas::MITGLIED_STAMMSEKTION_ROLES) }

    it "renders xlsx" do
      create_role("Mitglied", start_on: "15.2.2024", end_on: "15.8.2024") # eintritt and austritt
      create_role("Mitglied", start_on: "30.4.2024") # eintritt
      create_role("Mitglied", start_on: "15.2.2020", end_on: "30.6.2024") # austritt
      # stammsektion wechsel - not counted
      p = create_role("Mitglied", start_on: "31.12.2023", end_on: "30.9.2024").person
      create_role("Mitglied",
        start_on: "1.10.2024",
        end_on: "1.1.2025",
        group: groups(:matterhorn_mitglieder),
        person: p)
      # austritt and wiedereintritt in the same year - not counted
      p = create_role("Mitglied", start_on: "1.12.2023", end_on: "20.4.2024").person
      create_role("Mitglied", start_on: "10.10.2024", person: p)

      sheet.generate

      expect(xlsx.rows).to include(
        ["Aktive Mitglieder am 31.12.2024", :title],
        [],
        ["Anzahl Total", nil, 7],
        [],
        ["  Davon"],
        ["  - Geschlecht", "m", 0],
        ["  - Geschlecht", "w", 1],
        ["  - Geschlecht", "d", 6]
      )

      expect(xlsx.rows).to include(
        ["Eintritte 01.01.2024 - 31.12.2024", :title],
        ["  - Eintrittsgrund", "Keine Angabe", 2],
        ["  - Eintrittsgrund", "Weil der SAC eine gute Sache ist.", 0]
      )

      expect(xlsx.rows).to include(
        ["Austritte 01.01.2024 - 31.12.2024", :title],
        ["  - Austrittsgrund", "ADM", 2],
        ["  - Austrittsgrund", "Umgezogen", 0]
      )
    end
  end
end
