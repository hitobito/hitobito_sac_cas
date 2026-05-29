# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require_relative "row_collector"

describe Export::Xlsx::SacStatistics::MonthlyMutationsSheet do
  let(:range) { Date.new(2024, 1, 1)..Date.new(2024, 12, 31) }
  let(:xlsx) { RowCollector.new }
  let(:sheet) { described_class.new(xlsx, range) }

  def create_role(type, group = groups(:bluemlisalp_mitglieder), **attrs)
    Fabricate("Group::SektionsMitglieder::#{type}", group:, **attrs)
  end

  def numbers(month)
    xlsx.rows.find { |row| row.first == month }&.slice(1..)
  end

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
    # austritt and eintritt in the same year - counted
    p = create_role("Mitglied", start_on: "1.12.2023", end_on: "20.4.2024").person
    create_role("Mitglied", start_on: "10.10.2024", person: p)

    sheet.generate

    expect(xlsx.rows.first).to eq(
      ["Monat", "SAC-Eintritte", "SAC-Austritte", "Total aktive Mitglieder", :title]
    )
    expect(xlsx.rows.size).to eq(13)

    expect(numbers("01-2024")).to eq([0, 0, 7])
    expect(numbers("02-2024")).to eq([1, 0, 8])
    expect(numbers("03-2024")).to eq([0, 0, 8])
    expect(numbers("04-2024")).to eq([1, 1, 8])
    expect(numbers("05-2024")).to eq([0, 0, 8])
    expect(numbers("06-2024")).to eq([0, 1, 8])
    expect(numbers("07-2024")).to eq([0, 0, 7])
    expect(numbers("08-2024")).to eq([0, 1, 6])
    expect(numbers("09-2024")).to eq([0, 0, 6])
    expect(numbers("10-2024")).to eq([1, 0, 7])
    expect(numbers("11-2024")).to eq([0, 0, 7])
    expect(numbers("12-2024")).to eq([0, 0, 7])
  end
end
