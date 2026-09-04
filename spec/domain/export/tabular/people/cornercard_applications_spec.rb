# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::People::CornercardApplications do
  let(:person) do
    Person.create!(
      first_name: "Max",
      last_name: "Muster",
      email: "max@example.com",
      birthday: Date.new(1990, 1, 15),
      gender: "m",
      street: "Musterplatz",
      housenumber: "42",
      postbox: "Postfach 23",
      zip_code: "8000",
      town: "Zurich",
      country: "CH"
    )
  end

  subject(:tabular) { described_class.new(CornercardUpload.all) }

  its(:model_class) { is_expected.to eq Person }

  describe "attributes" do
    it "has expected attributes matching issue specification" do
      expect(tabular.attributes).to eq [
        :id,
        :last_name,
        :first_name,
        :gender,
        :birthday,
        :email,
        :mobile,
        :street,
        :housenumber,
        :postbox,
        :zip_code,
        :town,
        :country
      ]
    end
  end

  describe "labels" do
    it "has expected German labels" do
      expect(tabular.labels).to eq [
        "Mitgliedernummer",
        "Nachname",
        "Vorname",
        "Geschlecht",
        "Geburtsdatum",
        "Hauptemail",
        "Mobile",
        "Strasse",
        "Hausnummer",
        "Postfach",
        "PLZ",
        "Ort",
        "Land"
      ]
    end
  end

  describe "#data_rows" do
    it "contains all attributes for a person" do
      person.create_cornercard_upload!
      person.phone_numbers.create!(
        category: contact_account_categories(:phone_number_person_mobile),
        number: "+41 79 123 45 67"
      )

      rows = tabular.data_rows.to_a
      expect(rows.size).to eq 1

      expect(rows.first).to eq([
        person.id,
        "Muster",
        "Max",
        "m",
        "15.01.1990",
        "max@example.com",
        "+41 79 123 45 67",
        "Musterplatz",
        "42",
        "Postfach 23",
        "8000",
        "Zurich",
        "CH"
      ])
    end

    it "returns raw gender value" do
      person.create_cornercard_upload!

      rows = tabular.data_rows.to_a
      gender_index = tabular.attributes.index(:gender)
      expect(rows.first[gender_index]).to eq "m"
    end

    it "returns nil for missing mobile number" do
      person.create_cornercard_upload!

      rows = tabular.data_rows.to_a
      mobile_index = tabular.attributes.index(:mobile)
      expect(rows.first[mobile_index]).to be_nil
    end

    it "returns nil for missing birthday" do
      person.update!(birthday: nil)
      person.create_cornercard_upload!

      rows = tabular.data_rows.to_a
      birthday_index = tabular.attributes.index(:birthday)
      expect(rows.first[birthday_index]).to be_nil
    end

    it "returns nil for missing postbox" do
      person.update!(postbox: nil)
      person.create_cornercard_upload!

      rows = tabular.data_rows.to_a
      postbox_index = tabular.attributes.index(:postbox)
      expect(rows.first[postbox_index]).to be_nil
    end

    it "includes all pending uploads" do
      person.create_cornercard_upload!

      other_person = Person.create!(
        first_name: "Anna",
        last_name: "Zweiter",
        email: "anna@example.com",
        gender: "w"
      )
      other_person.create_cornercard_upload!

      rows = tabular.data_rows.to_a
      expect(rows.size).to eq 2
      expect(rows.pluck(tabular.attributes.index(:last_name))).to contain_exactly("Muster", "Zweiter")
    end
  end
end
