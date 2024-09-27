# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::SacSectionsImporter do
  let(:output) { double(puts: nil, print: nil) }
  let!(:importer) { described_class.new(output: output) }

  let(:section_bluemlisalp) { Group::Sektion.find_by(navision_id: 1650) }
  let(:section_burgdorf) { Group::Sektion.find_by(navision_id: 1850) }
  let(:section_yverdon) { Group::Sektion.find_by(navision_id: 5650) }
  let(:section_chasseral) { Group::Sektion.find_by(navision_id: 1900) }
  let(:ortsgruppe_burgdorf_damen) { Group::Sektion::Ortsgruppe.find_by(navision_id: 1853) }
  let(:section_drei_tannen) { Group::Sektion.find_by(navision_id: 2330) }
  let(:bluemlisalp_2024_membership_config_attrs) do
    {section_fee_adult: 60,
     section_fee_family: 120,
     section_fee_youth: 60,
     section_entry_fee_adult: 6,
     section_entry_fee_family: 6,
     section_entry_fee_youth: 0,
     bulletin_postage_abroad: 5,
     sac_fee_exemption_for_honorary_members: true,
     section_fee_exemption_for_honorary_members: true,
     sac_fee_exemption_for_benefited_members: false,
     section_fee_exemption_for_benefited_members: false,
     reduction_amount: 60,
     reduction_required_membership_years: 50,
     reduction_required_age: 0}
  end
  let(:bluemlisalp_membership_config_2024) { SacSectionMembershipConfig.find_by(group_id: section_bluemlisalp.id, valid_from: 2024) }

  before do
    test_csv_source_dir_path = Pathname.new(File.dirname(test_csv_source.path))
    csv_source_instance = SacImports::CsvSource.new(:NAV6, source_dir: test_csv_source_dir_path)
    importer.instance_variable_set(:@source_file, csv_source_instance)
  end

  context "Imports sections/ortsgruppe with attributes and membership configs" do
    let(:selected_test_section_ids) { [1650, 1850, 1853, 2330, 5650, 1900] }

    it "imports all sac sections with membership configs" do
      expect(section_bluemlisalp).to be_persisted

      expected_output = [
        "1650 SAC Blüemlisalp:",
        " ✅\n",
        "1850 SAC Burgdorf:",
        " ✅\n",
        "2330 SAC Drei Tannen:",
        " ✅\n",
        "5650 CAS Yverdon:",
        " ✅\n",
        "1900 CAS Chasseral:",
        " ✅\n",
        "1853 SAC Burgdorf Damen:",
        " ✅\n"
      ]

      expected_output.each do |output_line|
        expect(output).to receive(:print).with(output_line)
      end

      expect(output).to receive(:print).with(/❌/).never

      expect do
        importer.create
      end.to change { Group::Sektion.count }.by(4)
        .and change { Group::Ortsgruppe.count }.by(1)

      expect(section_burgdorf).to be_present
      expect(section_drei_tannen).to be_archived
      expect(section_yverdon.street).to eq("Rue du Collège")
      expect(section_yverdon.housenumber).to eq("7")
      expect(section_yverdon.postbox).to eq("Case postale 73")
      expect(section_yverdon.language).to eq("FR")
      neuanmeldungen_chasseral = Group::SektionsNeuanmeldungenSektion.find_by(parent_id: section_chasseral.id)
      expect(neuanmeldungen_chasseral).to be_present
      expect(neuanmeldungen_chasseral.custom_self_registration_title).to eq("Enregistrement à CAS Chasseral")

      # section Blüemlisalp
      section_bluemlisalp.reload
      expect(section_bluemlisalp).not_to be_archived
      expect(section_bluemlisalp.name).to eq("SAC Blüemlisalp")
      expect(section_bluemlisalp.zip_code).to eq(3600)
      expect(section_bluemlisalp.town).to eq("Thun")
      expect(section_bluemlisalp.address).to eq("Postfach")
      expect(section_bluemlisalp.section_canton).to eq("BE")
      expect(section_bluemlisalp.foundation_year).to eq(1874)
      expect(section_bluemlisalp.language).to eq("DE")
      expect(section_bluemlisalp.mitglied_termination_by_section_only).to be(true)
      expect(section_bluemlisalp.social_accounts.first.name).to eq("https://sac-bluemlisalp.ch/de/Sektion/Touren/Jugend")
      expect(section_bluemlisalp.email).to eq("sac-blemlisalp@example.ch")
      neuanmeldungen_bluemlisalp = Group::SektionsNeuanmeldungenNv.find_by(parent_id: section_bluemlisalp.id)
      expect(neuanmeldungen_bluemlisalp.custom_self_registration_title).to eq("Registrierung zu SAC Blüemlisalp")

      bluemlisalp_2024_membership_config_attrs.each do |key, value|
        expect(bluemlisalp_membership_config_2024.send(key)).to eq(value)
      end
    end

    it "reports failing sections in output" do
      # make section invalid
      Group.where(navision_id: section_bluemlisalp.navision_id).update_all(letter_address_position: "invalid")
      expect(section_bluemlisalp.reload).not_to be_valid

      expected_output = [
        "1650 SAC Blüemlisalp:",
        " ❌ Adressposition ist kein gültiger Wert\n",
        "1850 SAC Burgdorf:",
        " ✅\n",
        "2330 SAC Drei Tannen:",
        " ✅\n",
        "5650 CAS Yverdon:",
        " ✅\n",
        "1900 CAS Chasseral:",
        " ✅\n",
        "1853 SAC Burgdorf Damen:",
        " ✅\n"
      ]

      expected_output.each do |output_line|
        expect(output).to receive(:print).with(output_line)
      end

      importer.create
    end
  end

  context "creates sub groups" do
    let(:selected_test_section_ids) { [1850, 1853] }

    it "creates sac default sub groups for sektion + a ortsgruppe as sub group" do
      expect do
        importer.create
      end.to change { Group::Sektion.count }.by(1)
        .and change { Group::Ortsgruppe.count }.by(1)

      expected_sub_groups = [
        Group::SektionsFunktionaere,
        Group::SektionsMitglieder,
        Group::SektionsNeuanmeldungenNv
      ]

      expect(ortsgruppe_burgdorf_damen.children.count).to eq(expected_sub_groups.count)

      expected_sub_groups.each do |c|
        expect(c.where(parent_id: ortsgruppe_burgdorf_damen.id).count).to eq(1)
      end

      expect(section_burgdorf.children.count).to eq(expected_sub_groups.count + 1)

      expected_sub_groups.each do |c|
        expect(c.where(parent_id: section_burgdorf.id).count).to eq(1)
      end
    end
  end

  private

  def test_csv_source
    source_csv = HitobitoSacCas::Wagon.root.join("spec", "fixtures", "files", "sac_imports_src", "NAV6_fixture.csv")
    filtered_rows = CSV.read(source_csv, headers: true).select do |row|
      selected_test_section_ids.include?(row["NAV Sektions-ID"].to_i)
    end
    temp_csv = Tempfile.new(["NAV6_fixture-#{SecureRandom.alphanumeric(5)}", ".csv"])
    temp_csv.close
    CSV.open(temp_csv.path, "w") do |csv|
      csv << filtered_rows.first.headers
      filtered_rows.each do |row|
        csv << row
      end
    end
    temp_csv
  end
end
