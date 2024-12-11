# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Nav17EventKindsImporter do
  let(:sac_imports_src) { file_fixture("sac_imports_src").expand_path }
  let(:output) { double(puts: nil, print: nil) }
  let(:report) { described_class.new(output: output) }
  let(:report_file) { Rails.root.join("log", "sac_imports", "nav17-event-kinds_2024-01-23-1142.csv") }
  let(:report_headers) {
    %w[short_name label status errors]
  }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }

  before do
    File.delete(report_file) if File.exist?(report_file)
    stub_const("SacImports::CsvSource::SOURCE_DIR", sac_imports_src)

    load(HitobitoSacCas::Wagon.root.join("db", "seeds", "course_master_data.rb"))
    seed_cost_centers
    seed_cost_units
    seed_event_kind_categories
    seed_event_levels
    seed_course_compensation_categories
  end

  it "creates report for entries in source file" do
    expected_output = []
    expected_output << "Alpinwandern (S6570): ❌ Kurskategorie muss ausgefüllt werden, Saison ist kein gültiger Wert"

    expect(output).to receive(:puts).with("The file contains 9 rows.")
    expected_output.flatten.each do |output_line|
      expect(output).to receive(:puts).with(output_line)
    end
    expect(output).to receive(:puts).with("\n\n\nReport generated in 0.0 minutes.")
    expect(output).to receive(:puts).with("Thank you for flying with SAC Imports.")
    expect(output).to receive(:puts).with("Report written to #{report_file}")

    travel_to DateTime.new(2024, 1, 23, 10, 42)

    expect { report.create }
      .to change { Event::Kind.count }.by(8).and \
        change { Event::KindQualificationKind.count }.by(3)

    kind = Event::Kind.find_by(short_name: "S1460")
    expect(kind.attributes.symbolize_keys).to include(
      short_name: "S1460",
      label: "Alpine Umwelt",
      general_information: nil,
      application_conditions: "gute allgemeine Kondition für eine Wintertour in den Bergen mit Schneeschuhen",
      minimum_age: 18,
      minimum_participants: 4,
      maximum_participants: 8,
      ideal_class_size: 4,
      maximum_class_size: 8,
      maximum_age: nil,
      season: "winter",
      accommodation: "hut",
      training_days: 0.2e1,
      reserve_accommodation: false,
      section_may_create: false
    )
    expect(kind.kind_category.label).to eq("Diverse Kurse Winter")
    expect(kind.level.code).to eq(1)
    expect(kind.cost_center.code).to eq("2100026")
    expect(kind.cost_unit.code).to eq("A1300")
    I18n.with_locale(:fr) do
      expect(kind.label).to eq("Environnement alpin")
      expect(kind.application_conditions).to eq("bonne condition physique générale pour une course d’hiver en raquettes en montagne")
    end
    I18n.with_locale(:it) do
      expect(kind.label).to eq("Environnement alpin") # fallback to fr
    end

    kind = Event::Kind.find_by(short_name: "S5750")
    expect(kind.event_kind_qualification_kinds.size).to eq(2)
    kqk = kind.event_kind_qualification_kinds.first
    expect(kqk.qualification_kind.label).to be_in(["Ski Leiter", "Snowboard Leiter"])
    expect(kqk.category).to eq("prolongation")
    expect(kqk.role).to eq("participant")

    kind = Event::Kind.find_by(short_name: "S6560")
    expect(kind.section_may_create).to eq(true)
    expect(kind.event_kind_qualification_kinds.size).to eq(1)
    kqk = kind.event_kind_qualification_kinds.first
    expect(kqk.qualification_kind.label).to eq("Ski Leiter")
    expect(kqk.category).to eq("qualification")
    expect(kqk.role).to eq("participant")

    kind = Event::Kind.find_by(short_name: "S5780")
    expect(kind.course_compensation_categories).to be_blank

    expect(File.exist?(report_file)).to be_truthy

    expect(csv_report.size).to eq(3)
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report[1]).to eq(["S6570", "Alpinwandern", "warning",
      "kind_category with value '6990' couldn't be found, course_compensation_category with value 'HON-KAT-X' couldn't be found"])
    expect(csv_report[2]).to eq(["S6570", "Alpinwandern", "error",
      "Kurskategorie muss ausgefüllt werden, Saison ist kein gültiger Wert"])

    File.delete(report_file)
    expect(File.exist?(report_file)).to be_falsey
  end
end
