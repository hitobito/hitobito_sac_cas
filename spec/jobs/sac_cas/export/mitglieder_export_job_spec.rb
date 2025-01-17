# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SacCas::Export::MitgliederExportJob do
  let(:user) { people(:admin) }
  let(:group) { groups(:bluemlisalp) }
  subject(:job) { described_class.new(user.id, group.id) }

  let(:file) { job.send(:async_download_file) }
  let(:contents) { file.generated_file.download.force_encoding("ISO-8859-1") }
  let(:csv) { CSV.parse(contents.lines[0...-1].join, col_sep: "$") }
  let(:summary_line) { contents.lines.last }

  it "creates a CSV-Export" do
    freeze_time
    expect { job.perform }.to change { AsyncDownloadFile.count }.by(1)

    expect(csv).to have(4).items
    people_ids = csv.map(&:first).map { |entry| Integer(entry) }
    expect(people_ids).to contain_exactly(
      people(:mitglied).id,
      people(:familienmitglied).id,
      people(:familienmitglied2).id,
      people(:familienmitglied_kind).id
    )

    expect(summary_line).to eq(
      "* * * Dateiende * * * / " \
      "#{group.navision_id_padded} / " \
      "Anzahl Datensätze: 4 / " \
      "#{Time.zone.now.strftime("%d.%m.%Y")} / " \
      "#{Time.zone.now.strftime("%H:%M")}".encode("ISO-8859-1")
    )
  end

  describe "string quotation" do
    it "has no quotation marks for single line strings" do
      person = people(:mitglied)
      Person.where.not(id: people(:mitglied, :admin).map(&:id)).destroy_all
      expect { job.perform }.to change { AsyncDownloadFile.count }.by(1)
      expect(contents).to match(/\$#{person.last_name}\$#{person.first_name}\$/)
    end

    it "has quotation marks for multiline strings" do
      person = people(:mitglied)
      person.update!(first_name: "Hello\nWorld")
      Person.where.not(id: people(:mitglied, :admin).map(&:id)).destroy_all
      expect { job.perform }.to change { AsyncDownloadFile.count }.by(1)
      expect(contents).to match(/\$#{person.last_name}\$"#{person.first_name}"\$/)
    end

    it "has quotation marks for strings containing col_sep" do
      person = people(:mitglied)
      person.update!(first_name: "Hello$World")
      Person.where.not(id: people(:mitglied, :admin).map(&:id)).destroy_all
      expect { job.perform }.to change { AsyncDownloadFile.count }.by(1)
      expect(contents).to include %($#{person.last_name}$"Hello$World"$)
    end
  end

  # Core uses CSVSafe which prefix phone numbers starting with the + sign with a single quote.
  # This export generates a legacy file format which MUST NOT prefix phone numbers.
  it "does not prefix phone numbers with single quote" do
    person = people(:mitglied)
    person.phone_numbers.create!(number: "+41 79 123 45 67", label: "Haupt-Telefon")
    job.perform
    expect(contents).to include "$+41 79 123 45 67$"
  end

  it "file name" do
    job.perform
    expect(file.filename).to eq("Adressen_#{group.navision_id_padded}.csv")
  end
end
