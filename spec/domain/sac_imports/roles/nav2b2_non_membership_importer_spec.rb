# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SacImports::Roles::Nav2b2NonMembershipImporter do
  # :navision_id, # "Kontaktnummer",
  #   :family_id, # "Familiennummer",
  #   :valid_from, # "GültigAb",
  #   :valid_until, # "GültigBis",
  #   :layer_type, # "Layer",
  #   :group_level1, # "Gruppe_Lvl_1",
  #   :group_level2, # "Gruppe_Lvl_2",
  #   :group_level3, # "Gruppe_Lvl_3",
  #   :group_level4, # "Gruppe_Lvl_4",
  #   :role, # "Rolle",
  #   :role_description, # "Zusatzbeschrieb",
  #   :membership_years, # "Vereinsmitgliederjahre",
  #   :person_name, # "Name",
  #   :nav_verteilercode, # "NAV_Verteilercode",
  #   :beitragskategorie, # "Beitragskategorie",
  #   :sektionscode, # "Sektioncode",
  #   :sektionsname, # "Sektionname",
  #   :membership_kind # "Mitgliederart"

  let(:person) { people(:mitglied) }

  let(:row) do
    SacImports::CsvSource::Nav2.members.index_with(nil).merge(
      navision_id: person.id.to_s,
      valid_from: "2024-01-01",
      valid_until: "2024-12-31"
    )
  end
  let(:entry) { SacImports::CsvSource::Nav2.new(**row) }

  let(:csv_source) { double("source", rows: [entry]) }
  let(:csv_report) { double("report") }
  let(:output) { double("output") }

  let(:importer) { described_class.new(csv_source:, csv_report:, output:) }

  subject(:process_row) do
    importer.send(:process_row, entry)
  end

  context "#create_role" do
    it "creates a role"
    it "does not create duplicate roles"
  end

  context "#find" do
    it "finds a group"
    it "does not create group"
  end

  context "#load_or_create_group" do
    it "works correctly" # TODO: write meaningful tests
  end

  context "for Tourenleiter*in (mit Qualifikation) when missing qualification" do
    before do
      row.merge!(
        layer_type: "Sektion",
        group_level1: groups(:bluemlisalp).name,
        group_level2: "Sektionsfunktionäre",
        group_level3: "Touren und Kurse",
        role: "Tourenleiter*in (mit Qualifikation)",
        role_description: "SAC Tourenleiter*in aktiv"
      )
    end

    let!(:touren_und_kurse) do
      Group::SektionsTourenUndKurse.create!(parent: groups(:bluemlisalp_funktionaere))
    end

    it "creates a TourenleiterOhneQualifikation instead" do
      expect(person.qualifications).to be_empty

      expect(csv_report).to receive(:add_row).with(hash_including(
        message: "Role 'Tourenleiter*in (mit Qualifikation)' in 'Sektionsfunktionäre → Touren und Kurse'",
        status: "warning",
        target_group: "SAC Blüemlisalp > Sektionsfunktionäre > Touren und Kurse",
        target_role: "Tourenleiter*in (mit Qualifikation)",
        warning: "Person has no valid qualification for Tourenleiter role, created TourenleiterOhneQualifikation instead"
      ))

      expect { process_row }.to change { person.roles.count }.by(1)
      role = person.roles.last
      expect(role).to be_a(Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation)
      expect(role.label).to eq "SAC Tourenleiter*in aktiv"
      expect(role.group).to eq touren_und_kurse
    end
  end
end
