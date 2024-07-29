# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::CsvReport do
  let(:headers) { %i[membership_number sac_family_number name stammsektion] }
  let(:csv_report) { described_class.new(:"4_import_memberships", headers) }
  let(:report_file) { Rails.root.join("log", "sac_imports", "4_import_memberships_#{Time.zone.now.strftime("%Y-%m-%d-%H:%M")}.csv") }
  let(:csv_content) { CSV.read(report_file, col_sep: ";") }

  it "creates csv log with headers and appends rows" do
    freeze_time
    csv_report.add_row({membership_number: 1234,
                        sac_family_number: "F42",
                        name: "John Doe",
                        stammsektion: "SAC Bern"})
    expect(File.exist?(report_file)).to be_truthy
    expect(csv_content.first).to eq(headers.map(&:to_s))
    expect(csv_content.second).to eq(["1234", "F42", "John Doe", "SAC Bern"])

    File.delete(report_file)
    expect(File.exist?(report_file)).to be_falsey
  end
end
