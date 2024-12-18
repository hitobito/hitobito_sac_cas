# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Nav22ExternalTrainingsImporter do
  let(:sac_imports_src) { file_fixture("sac_imports_src").expand_path }
  let(:output) { double(puts: nil, print: nil) }
  let(:report) { described_class.new(output: output) }
  let(:report_file) { Rails.root.join("log", "sac_imports", "nav22-external-trainings_2024-01-23-1142.csv") }
  let(:report_headers) {
    %w[person_id start_at status errors]
  }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }

  before do
    File.delete(report_file) if File.exist?(report_file)
    stub_const("SacImports::CsvSource::SOURCE_DIR", sac_imports_src)

    create_event_kinds
    Person.find(600001).qualifications.create!(
      qualification_kind: qualification_kinds(:snowboard_leader),
      start_at: Date.new(2018, 7, 3),
      qualified_at: Date.new(2018, 7, 3),
      finish_at: Date.new(2024, 12, 31)
    )
  end

  after do
    # re-register callback
    ExternalTraining.after_save :issue_qualifications
  end

  it "creates report for entries in source file" do
    expected_output = []
    expected_output << "600001 - 2023-03-22: ❌ Kursart muss ausgefüllt werden"

    expect(output).to receive(:puts).with("The file contains 6 rows.")
    expected_output.flatten.each do |output_line|
      expect(output).to receive(:puts).with(output_line)
    end
    expect(output).to receive(:puts).with("\n\n\nReport generated in 0.0 minutes.")
    expect(output).to receive(:puts).with("Thank you for flying with SAC Imports.")
    expect(output).to receive(:puts).with("Report written to #{report_file}")

    travel_to DateTime.new(2024, 1, 23, 10, 42)

    expect { report.create }
      .to change { ExternalTraining.count }.by(4).and \
        change { Qualification.count }.by(0) # make sure no qualifications are issued

    t1 = ExternalTraining.first
    expect(t1.attributes.symbolize_keys).to include(
      person_id: 600000,
      name: "Leiterfortbildung Skifahren",
      provider: "extern",
      start_at: Date.new(2022, 4, 8),
      finish_at: Date.new(2022, 4, 10),
      training_days: 3,
      link: nil,
      remarks: nil
    )
    expect(t1.event_kind.label).to eq("Leiterfortbildung Skifahren")

    t3 = ExternalTraining.third
    expect(t3.attributes.symbolize_keys).to include(
      person_id: 600002,
      name: "Leiterfortbildung Snowboard",
      provider: "extern",
      start_at: Date.new(2022, 4, 15),
      finish_at: Date.new(2022, 4, 16),
      training_days: 2.5,
      link: nil,
      remarks: nil
    )

    expect(File.exist?(report_file)).to be_truthy

    expect(csv_report.size).to eq(4)
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report[1..]).to eq(
      [["699999", "2023-03-22", "error", "Person muss ausgefüllt werden"],
        ["600001", "2023-03-22", "warning", "event_kind with value X42 couldn't be found"],
        ["600001", "2023-03-22", "error", "Kursart muss ausgefüllt werden"]]
    )

    File.delete(report_file)
    expect(File.exist?(report_file)).to be(false)
  end

  def create_event_kinds
    default_attrs = {
      cost_unit: CostUnit.first,
      cost_center: CostCenter.first,
      kind_category: Event::KindCategory.first,
      level: Event::Level.first
    }
    ski = Fabricate(:event_kind, default_attrs.merge(label: "Leiterfortbildung Skifahren", short_name: "X01"))
    ski.event_kind_qualification_kinds.create!(qualification_kind: qualification_kinds(:ski_leader), role: "participant", category: "qualification")
    Fabricate(:event_kind, default_attrs.merge(label: "Leiterfortbildung Klettern", short_name: "X02"))
    sb = Fabricate(:event_kind, default_attrs.merge(label: "Leiterfortbildung Snowboard", short_name: "X03"))
    sb.event_kind_qualification_kinds.create!(qualification_kind: qualification_kinds(:snowboard_leader), role: "participant", category: "prolongation")
  end
end
