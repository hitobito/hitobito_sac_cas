# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::PeopleExportJob do
  let(:user) { people(:root) }
  let(:group) { groups(:bluemlisalp_mitglieder) }

  let(:filename) { AsyncDownloadFile.create_name("people_export", user.id) }
  let(:file) { AsyncDownloadFile.from_filename(filename, :csv) }
  let(:csv) { CSV.parse(file.read, col_sep: Settings.csv.separator.strip, headers: true) }

  it "works when including attribute membership_years" do
    job = Export::PeopleExportJob.new(
      :csv, user.id, group.id, {},
      full: true, filename: filename
    )

    job.perform

    expect(file.generated_file).to be_attached

    expect(csv).to have(4).items
    expect(csv.first["﻿Mitglied-Nr"]).to eq "600001"
    expect(csv.first["Anzahl Mitglieder-Jahre"]).to eq((Date.current.year - 2015).to_f.to_s)
  end

  context "with recipients param" do
    subject do
      Export::PeopleExportJob.new(:csv, user.id, group.id, {}, recipients: true, filename: "dummy")
    end

    it "uses SacRecipients tabular export" do
      expect(Export::Tabular::People::SacRecipients).to receive(:export)
      subject.perform
    end
  end
end
