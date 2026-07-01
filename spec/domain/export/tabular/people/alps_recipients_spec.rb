# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require_relative "alps_recipients_test_data"

describe Export::Tabular::People::AlpsRecipients do
  let(:reference_date) { Date.new(2025, 10, 1) }
  let(:new_entries_from) { nil }
  let(:scope) do
    Export::Tabular::People::AlpsRecipientsScope.new(reference_date, new_entries_from)
  end
  let(:table) { described_class.new(scope.regular(:de), reference_date, abonnent_group_langs) }
  let(:rows) { table.data_rows.to_a }
  let(:abonnent_group_langs) { scope.abonnent_group_ids.invert.transform_values(&:to_s) }

  include_context "alps recipients test data"

  context "regular table" do
    it "contains only limited attributes" do
      expect(table.labels).to eq(%w[
        nr
        name
        vorname
        adresszusatz
        adresse
        postfach
        laendercode
        plz
        ort
        anzahl_alpen
        sprache
      ])
    end

    it "contains correct data" do
      row = row_for(mitglied)
      expect(row).to eq([
        mitglied.id,
        "Hillary",
        "Edmund",
        nil,
        "Ophovenerstrasse 79a",
        nil,
        "CH",
        "2843",
        "Neu Carlscheid",
        1,
        "de"
      ])

      row = row_for(magazin_abonnent_company)
      expect(row[1]).to eq("My Company")
    end

    context "with new entries" do
      let(:new_entries_from) { Date.new(2025, 1, 1) }
      let(:table) { described_class.new(scope.new_entries(:fr), reference_date, abonnent_group_langs) }

      it "contains correct data" do
        row = row_for(new_entry_fr)
        expect(row).to eq([
          new_entry_fr.id,
          new_entry_fr.last_name,
          new_entry_fr.first_name,
          nil,
          "Ophovenerstrasse 79a",
          nil,
          "CH",
          "2843",
          "Neu Carlscheid",
          1,
          "fr"
        ])

        row = row_for(new_entry_abonnent_fr)
        expect(row).to eq([
          new_entry_abonnent_fr.id,
          new_entry_abonnent_fr.last_name,
          new_entry_abonnent_fr.first_name,
          nil,
          "Ophovenerstrasse 79a",
          nil,
          "CH",
          "2843",
          "Neu Carlscheid",
          1,
          "fr"
        ])
      end
    end
  end

  context "full table" do
    let(:table) { described_class.new(scope.all, reference_date, abonnent_group_langs, full: true) }

    it "contains all attributes" do
      expect(table.labels).to eq(%w[
        nr
        name
        vorname
        adresszusatz
        adresse
        postfach
        laendercode
        plz
        ort
        anzahl_alpen
        sprache
        geburtsdatum
        eintrittsdatum
        typ
        firma
      ])
    end

    it "contains correct data" do
      row = row_for(mitglied)
      expect(row).to eq([
        mitglied.id,
        "Hillary",
        "Edmund",
        nil,
        "Ophovenerstrasse 79a",
        nil,
        "CH",
        "2843",
        "Neu Carlscheid",
        1,
        "de",
        "01.01.2000",
        "01.01.2015",
        "Mitglied",
        "nein"
      ])

      # abonnent company fields
      row = row_for(magazin_abonnent_company)
      expect(row[1]).to eq("My Company")
      expect(row[11]).to be_nil
      expect(row[12]).to eq("01.08.2021")
      expect(row[13]).to eq("Abonnent")
      expect(row[14]).to eq("ja")

      # mitglied and abonnent is considered mitglied
      row = row_for(mitglied_and_abonnent)
      expect(row[11]).to eq(mitglied_and_abonnent.birthday.strftime("%d.%m.%Y"))
      expect(row[12]).to eq("22.04.2022")
      expect(row[13]).to eq("Mitglied")
      expect(row[14]).to eq("nein")

      # sac entry date is used as entry_on
      row = row_for(new_entry)
      expect(row[12]).to eq("20.07.2025")

      # abonnent start_on date is used as entry_on
      row = row_for(new_entry_abonnent_fr)
      expect(row[12]).to eq("15.06.2025")

      # first sac entry date is used as entry_on with beitragskategoriewechsel
      row = row_for(beitragskategoriewechsel)
      expect(row[12]).to eq("18.05.2022")

      # first sac entry date is used as entry_on with sektionswechsel
      row = row_for(sektionswechsel_before_new_entries_from)
      expect(row[12]).to eq("12.02.2020")

      # first sac entry date is used as entry_on with old memberships
      row = row_for(new_entry_with_old_membership)
      expect(row[12]).to eq("28.09.2015")

      # current abonnent start_on is used as entry_on
      row = row_for(new_entry_abonnent_with_old_abo)
      expect(row[12]).to eq("11.01.2023")

      # current abonnent start_on is used as entry_on
      row = row_for(old_mitglied_new_abonnent_fr)
      expect(row[10]).to eq("fr")
      expect(row[12]).to eq("01.03.2025")
    end

    it "does not do N+1 queries" do
      expect { rows }.to make(4).db_queries
    end
  end

  def row_for(person)
    rows.find { |row| row.first == person.id }
  end
end
