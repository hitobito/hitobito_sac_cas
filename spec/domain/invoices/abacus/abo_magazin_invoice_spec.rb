# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::Abacus::AboMagazinInvoice do
  let(:abonnent_alpen) { roles(:abonnent_alpen) }
  let(:abonnent) { people(:abonnent) }

  subject { described_class.new(abonnent_alpen, Date.new(2026, 1, 1)) }

  before do
    Group.root.update!(abo_alpen_fee: 60, abo_alpen_postage_abroad: 16, abo_alpen_fee_article_number: "APG")
  end

  describe "#positions" do
    context "for swiss person" do
      before do
        abonnent.update_column(:country, "CH")
      end

      it "creates abo fee position with correct values" do
        position = subject.positions.first
        expect(subject.positions.count).to eq 1
        expect(position.name).to eq "Abonnement Die Alpen DE 01.01.2026 - 31.12.2026"
        expect(position.grouping).to eq "Abonnement Die Alpen DE 01.01.2026 - 31.12.2026"
        expect(position.amount).to eq 60
        expect(position.count).to eq 1
        expect(position.article_number).to eq "APG"
      end

      it "position uses language of person as locale" do
        abonnent.update_column(:language, :it)
        allow(I18n).to receive(:t).and_call_original
        allow(I18n).to receive(:t)
          .with("invoices.abo_magazin.positions.abo_fee", group: abonnent_alpen.group, time_period: subject.send(:new_role_period), locale: "it")
          .and_return("Abbonamento Die Alpen DE 01.01.2026 - 31.12.2026")

        expect(subject.positions.first.name).to eq "Abbonamento Die Alpen DE 01.01.2026 - 31.12.2026"
      end
    end

    context "for person living abroad" do
      before do
        abonnent.update_column(:country, "BO")
      end

      it "has second position for abroad costs" do
        position = subject.positions.second
        expect(subject.positions.count).to eq 2
        expect(position.name).to eq "Porto Die Alpen DE"
        expect(position.grouping).to eq "Porto Die Alpen DE"
        expect(position.amount).to eq 16
        expect(position.count).to eq 1
        expect(position.article_number).to eq "APG"
      end
    end
  end

  describe "#total" do
    context "for swiss person" do
      before do
        abonnent.update_column(:country, "CH")
      end

      it "total does not include porto cost" do
        expect(subject.total).to eq 60
      end
    end

    context "for person living abroad" do
      before do
        abonnent.update_column(:country, "BO")
      end

      it "total does include porto cost" do
        expect(subject.total).to eq 76
      end
    end
  end

  describe "#invoice?" do
    it "is true when all required values are defined" do
      expect(subject.invoice?).to be_truthy
    end

    [:abo_alpen_fee_article_number, :abo_alpen_fee, :abo_alpen_postage_abroad].each do |attr|
      it "is false when #{attr} is not defined" do
        Group.root.update!(attr => nil)
        expect(subject.invoice?).to be_falsey
      end
    end
  end
end
