# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::SubscriptionsJob do
  let(:user) { people(:admin) }
  let(:mailing_list) { mailing_lists(:newsletter) }

  context "with recipients param" do
    subject(:job) do
      described_class.new(:csv, user.id, mailing_list.id, recipients: true, filename: "dummy")
    end

    it "uses SacRecipients tabular export" do
      expect(Export::Tabular::People::SacRecipients).to receive(:export)
      job.perform
    end
  end

  context "with recipient_households param" do
    subject(:job) do
      described_class.new(:csv, user.id, mailing_list.id, recipient_households: true, filename: "dummy")
    end

    it "uses SacRecipients tabular export" do
      expect(Export::Tabular::People::SacRecipientHouseholds).to receive(:export)
      job.perform
    end
  end

  context "with selection param triggering table display export" do
    subject(:job) do
      described_class.new(:csv, user.id, mailing_list.id, selection: true, filename: "dummy")
    end

    def export_table_display_as_csv
      Tempfile.create do |file|
        Subscription.create!(mailing_list: mailing_list, subscriber: people(:familienmitglied))
        expect(Export::Tabular::People::TableDisplays).to receive(:export).and_call_original
        expect(AsyncDownloadFile).to receive(:maybe_from_filename).and_return(file)
        job.perform
        file.rewind
        yield CSV.parse(file.read, col_sep: ";", headers: true)
      end
    end

    it "suceeds in exporting with Familien ID" do
      export_table_display_as_csv do |csv|
        expect(csv.headers).to include "Familien ID"
        expect(csv.pluck("Familien ID").compact.uniq).to eq %w[F4242]
      end
    end

    it "exports row but without membership_years" do
      TableDisplay.create!(person_id: user.id, selected: %w[language membership_years], table_model_class: "Person")
      export_table_display_as_csv do |csv|
        expect(csv.headers).to include "Sprache"
        expect(csv.pluck("Sprache").compact.uniq).to eq %w[de]
        expect(csv.headers).not_to include "Anzahl Mitglieder-Jahre"
      end
    end
  end
end
