# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::AlpsRecipientsExportJob do
  let(:user) { people(:admin) }
  let(:reference_date) { Date.new(2025, 6, 1) }
  let(:new_entries_from) { nil }
  let(:file) { job.job_observation }

  subject(:job) { described_class.new(user.id, "Empfängerlisten", reference_date, new_entries_from) }

  before do
    Group::AboMagazin.create!(name: "Les Alps FR", parent: groups(:abo_magazine))
    Group::AboMagazin.create!(name: "Le Alpi IT", parent: groups(:abo_magazine))
  end

  def zip_entries(file)
    zip_data = file.generated_file.download
    [].tap do |entries|
      Zip::InputStream.open(StringIO.new(zip_data)) do |zip|
        while (entry = zip.get_next_entry)
          entries << entry.name
        end
      end
    end
  end

  context "without new entries" do
    it "creates a zip export with the five primary files" do
      expect { job.enqueue! }.to change { JobObservation.count }.by(1)
      job.perform

      expect(file.filename).to eq("Empfaengerlisten")
      expect(file.filename_with_extension).to eq("Empfaengerlisten.zip")

      expect(zip_entries(file)).to contain_exactly(
        "AlpenD.xlsx",
        "AlpenF.xlsx",
        "AlpenI.xlsx",
        "AlpenDeutschland.xlsx",
        "Alpen.xlsx"
      )
    end
  end

  context "with new entries" do
    let(:new_entries_from) { Date.new(2025, 1, 1) }

    it "creates a zip export with the five primary files plus new member files" do
      expect { job.enqueue! }.to change { JobObservation.count }.by(1)
      job.perform

      expect(zip_entries(file)).to contain_exactly(
        "AlpenD.xlsx",
        "AlpenF.xlsx",
        "AlpenI.xlsx",
        "AlpenDeutschland.xlsx",
        "Alpen.xlsx",
        "DE_NeumitgliederHuettenkarte.xlsx",
        "FR_NeumitgliederHuettenkarte.xlsx",
        "IT_NeumitgliederHuettenkarte.xlsx"
      )
    end
  end
end
