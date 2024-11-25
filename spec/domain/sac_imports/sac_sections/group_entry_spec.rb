# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SacImports::SacSections::GroupEntry do
  let(:source) { SacImports::CsvSource::SOURCES[:NAV6] }
  let(:data) { source.new(**row.reverse_merge(source.members.index_with(nil))) }

  let(:row) do
    {
      navision_id: "00000042",
      level_1_id: "00001000",
      level_2_id: "00000042",
      is_active: "1",
      section_name: "SAC Testsektion",
      foundation_year: "42",
      language: "deutsch",

      section_fee_adult: "42.00",
      section_fee_family: "77.00",
      section_fee_youth: "28.00",
      section_entry_fee_adult: "10.00",
      section_entry_fee_family: "10.00",
      section_entry_fee_youth: "0.00",
      bulletin_postage_abroad: "0.00",
      sac_fee_exemption_for_honorary_members: "1",
      section_fee_exemption_for_honorary_members: "1",
      sac_fee_exemption_for_benefited_members: "0",
      section_fee_exemption_for_benefited_members: "0",
      reduction_amount: "42.00",
      reduction_required_membership_years: "40",
      reduction_required_age: "0"
    }
  end

  subject(:entry) { described_class.new(data) }

  it "works in principle" do
    expect { entry.import! }.to change { Group.count }
  end

  describe "mailing_lists" do
    it "sektionsbulletin paper creates the mailing list" do
      row[:has_bulletin_paper] = "1"

      expect { entry.import! }
        .to change { MailingList.count }.by(1)
        .and change { MailingList.where(group_id: 42).count }.by(1)

      list = MailingList.last
      expect(list.name).to eq("Sektionsbulletin physisch")
      expect(list.internal_key).to eq SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY
      expect(list.subscribable_for).to eq("configured")
      expect(list.subscribable_mode).to eq("opt_out")
      expect(list.filter_chain.to_hash).to eq(
        "invoice_receiver" =>
           {"stammsektion" => "true", "zusatzsektion" => "true", "group_id" => "42"}
      )
    end

    it "sektionsbulletin digital creates the mailing list" do
      row[:has_bulletin_digital] = "1"

      expect { entry.import! }
        .to change { MailingList.count }.by(1)
        .and change { MailingList.where(group_id: 42).count }.by(1)

      list = MailingList.last
      expect(list.name).to eq("Sektionsbulletin digital")
      expect(list.internal_key).to eq SacCas::MAILING_LIST_SEKTIONSBULLETIN_DIGITAL_INTERNAL_KEY
      expect(list.subscribable_for).to eq("anyone")
      expect(list.subscribable_mode).to eq("opt_in")
      expect(list.filter_chain).to be_blank
    end

    it "both bulletins creates both mailing lists" do
      row[:has_bulletin_digital] = "1"
      row[:has_bulletin_paper] = "1"

      expect { entry.import! }
        .to change { MailingList.count }.by(2)
        .and change { MailingList.where(group_id: 42).count }.by(2)
    end

    it "with invalid values it does not create mailing lists" do
      row[:has_bulletin_digital] = "hello"
      row[:has_bulletin_paper] = true

      expect { entry.import! }
        .not_to change { MailingList.count }
    end
  end
end
