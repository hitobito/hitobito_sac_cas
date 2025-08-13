# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe AccountCompletion do
  describe "::validations" do
    let(:model) { described_class.new }

    it "is invalid without person" do
      expect(model).not_to be_valid
      expect(model).to have(1).error_on(:person)
    end

    context "update context" do
      it "is invalid with blank attrs" do
        model.person = people(:mitglied)
        expect(model.valid?).to eq true
        expect(model.valid?(:update)).to eq false
        expect(model.errors.full_messages).to eq [
          "E-Mail muss ausgefüllt werden",
          "Passwort muss ausgefüllt werden",
          "E-Mail Bestätigung muss ausgefüllt werden",
          "Passwort Bestätigung muss ausgefüllt werden"
        ]
      end
      it "is valid if attrs are set correctly" do
        model.person = people(:mitglied)
        model.email = "test@example.com"
        model.email_confirmation = "test@example.com"
        model.password = "testtesttest"
        model.password_confirmation = "testtesttest"
        expect(model.valid?(:update)).to eq true
      end

      it "requires confirmations to match related attrs" do
        model.person = people(:mitglied)
        model.email = "test@example.com"
        model.email_confirmation = "test1@example.com"
        model.password = "testtesttest"
        model.password_confirmation = "testtesttest1"
        expect(model.valid?(:update)).to eq false
        expect(model.errors.full_messages).to eq [
          "E-Mail Bestätigung stimmt nicht mit E-Mail überein",
          "Passwort Bestätigung stimmt nicht mit Passwort überein"
        ]
      end
    end
  end

  describe "::generate" do
    let(:host) { "http://localhost:3000" }
    let(:csv) {}
    let(:scope) { Person.limit(2) }

    def token_url(name)
      token = AccountCompletion.find_by(person: people(name)).token
      "#{host}/account_completion?token=#{token}"
    end

    it "generates account completion models for scope" do
      expect do
        described_class.generate(scope, host:)
      end.to change { AccountCompletion.count }.by(scope.size)
    end

    it "generates csv data with person_id and account_completion_url" do
      csv = CSV.parse(described_class.generate(scope, host:), headers: true)
      expect(csv.headers).to eq %w[person_id account_completion_url]
      expect(csv.entries).to have(2).items
      expect(csv[0]["person_id"]).to eq "600000"
      expect(csv[1]["person_id"]).to eq "600001"
      expect(csv[0]["account_completion_url"]).to eq(token_url(:admin))
      expect(csv[1]["account_completion_url"]).to eq(token_url(:mitglied))
    end

    it "re-running returns existing models" do
      csv_one = CSV.parse(described_class.generate(scope, host:), headers: true)
      csv_two = CSV.parse(described_class.generate(scope, host:), headers: true)
      expect(csv_one[0]["person_id"]).to eq csv_two[0]["person_id"]
      expect(csv_one[0]["token"]).to eq csv_two[0]["token"]
    end
  end

  describe "#expired?" do
    let(:model) { described_class.new }

    it "is true when created more than 3 months ago" do
      expect(described_class.new(created_at: Time.zone.now)).not_to be_expired
      expect(described_class.new(created_at: 2.months.ago)).not_to be_expired
      expect(described_class.new(created_at: 4.months.ago)).to be_expired
    end
  end
end
