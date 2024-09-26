# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Wso2PeopleImporter do
  let(:sac_imports_src) { file_fixture("sac_imports_src").expand_path }
  let(:report_file) { Rails.root.join("log", "sac_imports", "wso21-1_people_2024-01-23-11:42.csv") }
  let(:output) { $stdout } # double(puts: nil, print: nil) }
  let(:report) { described_class.new(output: output) }
  let(:report_headers) { %w[navision_id first_name last_name warnings errors] }

  let!(:existing_person_matching) { Fabricate(:person, id: 4200000, email: "example@example.com", correspondence: "print") }
  let!(:existing_person_mismatch) { Fabricate(:person, id: 4200003, email: "wrong@example.com") }

  before do
    travel_to DateTime.new(2024, 1, 23, 10, 42)
    Group::AboBasicLogin.create!(parent: groups(:abos))
    Group::AboTourenPortal.create!(parent: groups(:abos))
    Group::ExterneKontakte.create!(name: "Navision Import", parent: Group::SacCas.first!)
    allow(Rails.root)
      .to receive(:join)
      .and_call_original
    allow(Rails.root)
      .to receive(:join)
      .with("tmp", "sac_imports_src")
      .and_return(sac_imports_src)
  end

  it "creates report for members in source file" do
    expected_output = [
      "4200000 (example@example.com):", " ✅\n",
      " (foobar3@gmail.com):", " ✅\n",
      " (foobaz@web.de):", " ✅\n",
      "4200001 (foo.baz@bluewin.ch):", " ❌ navision_id present put person not found\n",
      "4200002 (foobar84@gmail.com):", " ❌ navision_id present put person not found\n",
      "4200003 (foo-bar@gmx.digital):", " ❌ Email foo-bar@gmx.digital does not match the current email\n",
      " (nl1337@hotmail.com):", " ✅\n",
      "4200004 (foobarbaz@bluewin.ch):", " ❌ navision_id present put person not found\n",
      "4200005 (foo.bar-baz@bluewin.ch):", " ❌ navision_id present put person not found\n"
    ]
    expected_output.each do |output_line|
      expect(output).to receive(:print).with(output_line)
    end
    expect(output).to receive(:puts).with("\n\n\nReport generated in 0.0 minutes.")
    expect(output).to receive(:puts).with("Thank you for flying with SAC Imports.")
    expect(output).to receive(:puts).with("Report written to #{report_file}")

    expect do
      report.create
      existing_person_matching.reload
    end
      .to change(Person, :count).by(3)
      .and change { existing_person_matching.wso2_legacy_password_hash }
      .and change { existing_person_matching.wso2_legacy_password_salt }
      .and change { existing_person_matching.confirmed_at }
      .and change { existing_person_matching.correspondence }.to("digital")
      .and not_change { existing_person_mismatch.reload }

    expect(File.exist?(report_file)).to be_truthy

    csv_report = CSV.read(report_file, col_sep: ";")
    expect(csv_report.size).to eq(8)
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report.pluck(0)).to eq(["navision_id", nil, "4200001", "4200002", "4200003", nil, "4200004", "4200005"])
    expect(csv_report.pluck(3)).to eq(["warnings", "Email not verified", nil, nil, nil, "Email not verified", nil, nil])

    File.delete(report_file)
    expect(File.exist?(report_file)).to be_falsey
  end
end
