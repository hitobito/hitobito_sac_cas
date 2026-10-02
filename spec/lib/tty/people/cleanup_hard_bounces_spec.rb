# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require "csv"
require "tmpdir"
require "tty/helpers/format"
require "tty/helpers/paper_trailed"
require "tty/command"
require "tty/people/cleanup_hard_bounces"

describe TTY::People::CleanupHardBounces do
  let(:mitglied) { people(:mitglied) }
  let(:admin) { people(:admin) }

  let(:tmpdir) { Dir.mktmpdir }
  let(:input_path) { File.join(tmpdir, "hard_bounces.csv") }
  let(:output_path) { File.join(tmpdir, "report.csv") }

  after { FileUtils.remove_entry(tmpdir) }

  def write_input(*rows, col_sep: ",")
    CSV.open(input_path, "w", col_sep: col_sep) do |csv|
      csv << %w[person_id email bounce_type bounce_reason]
      rows.each { |row| csv << row }
    end
  end

  def run(dry_run: false)
    output = StringIO.new
    original_stdout = $stdout
    $stdout = output
    described_class.new.run(input_path, output_path: output_path, dry_run: dry_run)
    output.string
  ensure
    $stdout = original_stdout
  end

  def report_rows = CSV.read(output_path, headers: true).map(&:to_h)

  context "person without login in the last year" do
    before { mitglied.update_columns(last_sign_in_at: 2.years.ago, correspondence: "digital") }

    it "removes the email and switches correspondence to print" do
      write_input([mitglied.id, mitglied.email, "hard", "mailbox does not exist"])

      run

      expect(mitglied.reload.email).to be_nil
      expect(mitglied.correspondence).to eq "print"
    end

    it "reports the taken actions" do
      write_input([mitglied.id, mitglied.email, "hard", "mailbox does not exist"])

      run

      expect(report_rows).to eq [{
        "person_id" => mitglied.id.to_s,
        "email" => "e.hillary@hitobito.example.com",
        "bounce_type" => "hard",
        "bounce_reason" => "mailbox does not exist",
        "last_sign_in_at" => 2.years.ago.to_fs(:db),
        "email_removed" => "true",
        "correspondence_before" => "digital",
        "correspondence_after" => "print",
        "status" => "updated",
        "details" => nil
      }]
    end
  end

  it "removes the email of a person who never logged in" do
    mitglied.update_columns(last_sign_in_at: nil)
    write_input([mitglied.id, mitglied.email, "hard", "unknown recipient"])

    run

    expect(mitglied.reload.email).to be_nil
    expect(report_rows.first).to include("email_removed" => "true", "status" => "updated")
  end

  it "keeps the email of a person who logged in within the last year" do
    mitglied.update_columns(last_sign_in_at: 30.days.ago, correspondence: "digital")
    write_input([mitglied.id, mitglied.email, "hard", "mailbox full"])

    run

    expect(mitglied.reload.email).to eq "e.hillary@hitobito.example.com"
    expect(mitglied.correspondence).to eq "print"
    expect(report_rows.first).to include(
      "email_removed" => "false",
      "status" => "updated",
      "details" => "signed in at #{30.days.ago.to_fs(:db)}"
    )
  end

  it "keeps the email if it no longer matches the bounced one" do
    mitglied.update_columns(last_sign_in_at: nil, correspondence: "digital")
    write_input([mitglied.id, "outdated@hitobito.example.com", "hard", "mailbox does not exist"])

    run

    expect(mitglied.reload.email).to eq "e.hillary@hitobito.example.com"
    expect(mitglied.correspondence).to eq "print"
    expect(report_rows.first).to include(
      "email_removed" => "false",
      "details" => "primary email e.hillary@hitobito.example.com differs from bounced email"
    )
  end

  it "ignores the case of the bounced email" do
    mitglied.update_columns(last_sign_in_at: nil)
    write_input([mitglied.id, mitglied.email.upcase, "hard", "mailbox does not exist"])

    run

    expect(mitglied.reload.email).to be_nil
  end

  it "reports people without primary email as unchanged" do
    mitglied.update_columns(email: nil, last_sign_in_at: nil, correspondence: "print")
    write_input([mitglied.id, "gone@hitobito.example.com", "hard", "mailbox does not exist"])

    run

    expect(report_rows.first).to include(
      "status" => "unchanged",
      "email_removed" => "false",
      "details" => "no primary email"
    )
  end

  it "reports people that do not exist" do
    write_input([-1, "nobody@hitobito.example.com", "hard", "mailbox does not exist"])

    run

    expect(report_rows.first).to include(
      "person_id" => "-1",
      "status" => "person_not_found",
      "email_removed" => "false"
    )
  end

  it "reports people that cannot be saved without changing them" do
    mitglied.update_columns(town: "", last_sign_in_at: nil)
    write_input([mitglied.id, mitglied.email, "hard", "mailbox does not exist"])

    run

    expect(mitglied.reload.email).to eq "e.hillary@hitobito.example.com"
    row = report_rows.first
    expect(row).to include("status" => "error", "email_removed" => "false")
    expect(row["details"]).to match(/Ort/)
  end

  it "writes one row per person of the input csv" do
    mitglied.update_columns(last_sign_in_at: nil)
    admin.update_columns(last_sign_in_at: nil)
    write_input(
      [mitglied.id, mitglied.email, "hard", "mailbox does not exist"],
      [admin.id, admin.email, "hard", "domain not found"]
    )

    run

    expect(report_rows.pluck("person_id")).to eq [mitglied.id.to_s, admin.id.to_s]
  end

  it "reads semicolon separated csv files" do
    mitglied.update_columns(last_sign_in_at: nil)
    write_input([mitglied.id, mitglied.email, "hard", "mailbox does not exist"], col_sep: ";")

    run

    expect(mitglied.reload.email).to be_nil
  end

  it "rolls back all changes but still writes the report on a dry run" do
    mitglied.update_columns(last_sign_in_at: nil, correspondence: "digital")
    write_input([mitglied.id, mitglied.email, "hard", "mailbox does not exist"])

    run(dry_run: true)

    expect(mitglied.reload.email).to eq "e.hillary@hitobito.example.com"
    expect(mitglied.correspondence).to eq "digital"
    expect(report_rows.first).to include("email_removed" => "true", "status" => "updated")
  end

  it "fails if the input file is missing a required header" do
    CSV.open(input_path, "w") do |csv|
      csv << %w[person_id email]
      csv << [mitglied.id, mitglied.email]
    end

    expect { run }.to raise_error(/bounce_type, bounce_reason/)
  end

  it "fails if the input file does not exist" do
    expect { run }.to raise_error(/not found/)
  end
end
