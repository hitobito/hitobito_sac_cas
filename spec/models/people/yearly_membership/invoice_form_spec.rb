# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe People::YearlyMembership::InvoiceForm do
  let(:now) { Time.zone.local(2024, 8, 24, 1) }

  subject(:form) { described_class.new }

  before { travel_to(now) }

  describe "validations" do
    let(:required_attrs) do
      {
        invoice_year: now.year,
        invoice_date: 1.day.ago,
        send_date: 3.days.ago
      }
    end

    before { form.attributes = required_attrs }

    it "is valid with all params set" do
      expect(form).to be_valid
    end

    describe "invoice_year" do
      it "is invalid when blank" do
        form.invoice_year = nil
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Rechnungsjahr muss ausgefüllt werden"]
      end

      it "is invalid when short of min year" do
        form.invoice_year = now.year - 1
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Rechnungsjahr ist kein gültiger Wert"]
      end

      it "is invalid when exceeds max year" do
        form.invoice_year = now.year + 2
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to match_array ["Rechnungsjahr ist kein gültiger Wert"]
      end
    end

    describe "invoice_date" do
      it "is invalid when blank" do
        form.invoice_date = nil
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Buchungsdatum muss ausgefüllt werden"]
      end

      it "is invalid when short of min date" do
        form.invoice_date = 1.year.ago.end_of_year
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Buchungsdatum muss 01.01.2024 oder danach sein"]
      end

      it "is invalid when exceeds max date" do
        form.invoice_date = 2.years.from_now.beginning_of_year.to_date
        expect(form).not_to be_valid
        # rubocop:todo Layout/LineLength
        expect(form.errors.full_messages).to match_array ["Buchungsdatum muss 31.12.2025 oder davor sein"]
        # rubocop:enable Layout/LineLength
      end
    end

    describe "send_date" do
      it "is invalid when blank" do
        form.send_date = nil
        expect(form).not_to be_valid
        # rubocop:todo Layout/LineLength
        expect(form.errors.full_messages).to eq ["Versand- und Rechnungsdatum muss ausgefüllt werden"]
        # rubocop:enable Layout/LineLength
      end

      it "is invalid when short of min date" do
        form.send_date = 1.year.ago.end_of_year
        expect(form).not_to be_valid
        # rubocop:todo Layout/LineLength
        expect(form.errors.full_messages).to eq ["Versand- und Rechnungsdatum muss 01.01.2024 oder danach sein"]
        # rubocop:enable Layout/LineLength
      end

      it "is invalid when exceeds max date" do
        form.send_date = 2.years.from_now.beginning_of_year.to_date
        expect(form).not_to be_valid
        # rubocop:todo Layout/LineLength
        expect(form.errors.full_messages).to match_array ["Versand- und Rechnungsdatum muss 31.12.2025 oder davor sein"]
        # rubocop:enable Layout/LineLength
      end
    end

    describe "role_finish_date" do
      it "is valid when blank" do
        form.role_finish_date = nil
        expect(form).to be_valid
      end

      it "is invalid when short of min date" do
        form.role_finish_date = 1.year.ago.end_of_year
        expect(form).not_to be_valid
        # rubocop:todo Layout/LineLength
        expect(form.errors.full_messages).to eq ["Rollen verlängern bis muss 01.01.2024 oder danach sein"]
        # rubocop:enable Layout/LineLength
      end

      it "is invalid when exceeds max date" do
        form.role_finish_date = 2.years.from_now.beginning_of_year.to_date
        expect(form).not_to be_valid
        # rubocop:todo Layout/LineLength
        expect(form.errors.full_messages).to match_array ["Rollen verlängern bis muss 31.12.2025 oder davor sein"]
        # rubocop:enable Layout/LineLength
      end
    end
  end

  describe "date ranges" do
    it "spans start of current to end of next year" do
      expect(form.min_date).to eq Date.new(2024, 1, 1)
      expect(form.max_date).to eq Date.new(2025, 12, 31)
      expect(form.min_year).to eq(2024)
      expect(form.max_year).to eq(2025)
    end
  end
end
