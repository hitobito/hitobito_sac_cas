# frozen_string_literal: true

require "spec_helper"

describe Invoices::SacMemberships::ManualPositionGenerator do
  let(:sac) { Group.root }
  let(:person) { people(:mitglied) }
  let(:date) { Date.new(2023, 1, 1) }
  let(:context) { Invoices::SacMemberships::Context.new(date) }
  let(:member) {
    Invoices::SacMemberships::Member.new(context.people_with_membership_years.find(person.id),
      context)
  }
  let(:config) { context.config }
  let(:main_section) { groups(:bluemlisalp) }
  let(:additional_section) { groups(:matterhorn) }
  let(:ausserberg_section) { groups(:bluemlisalp_ortsgruppe_ausserberg) }
  let(:ausserberg_mitglieder) { groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder) }
  let(:memberships) { member.active_memberships }
  let(:new_entry) { false }
  let(:positions) { described_class.new(member, manual_positions).generate(memberships, new_entry:) }
  let(:sac_entry_fee) { nil }
  let(:section_entry_fee) { nil }
  let(:manual_positions) do
    {
      sac_fee: 100,
      sac_entry_fee: sac_entry_fee,
      hut_solidarity_fee: 30,
      sac_magazine: 25,
      sac_magazine_postage_abroad: 35,
      section_entry_fee: section_entry_fee,
      section_fees: manual_section_fee_positions,
      section_bulletin_postage_abroads: manual_section_bulletin_positions
    }
  end

  let(:manual_section_fee_positions) do
    [
      {section_id: main_section.id, fee: 40},
      {section_id: ausserberg_section.id, fee: 42},
      {section_id: additional_section.id, fee: 45}
    ]
  end

  let(:manual_section_bulletin_positions) do
    [
      {section_id: main_section.id, fee: 13},
      {section_id: ausserberg_section.id, fee: 15},
      {section_id: additional_section.id, fee: 18}
    ]
  end

  let(:magazine_list) { mailing_lists(:sac_magazine) }
  let(:section_bulletin_bluemlisalp) { mailing_lists(:section_bulletin_bluemlisalp) }

  before do
    SacMembershipConfig.update_all(valid_from: 2020)
    SacSectionMembershipConfig.update_all(valid_from: 2020)
    Role.update_all(end_on: date + 3.months)

    # individuelle zusatzmitgliedschaften
    Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
      person: people(:familienmitglied),
      group: ausserberg_mitglieder,
      beitragskategorie: :adult,
      start_on: date,
      end_on: date + 3.months
    )
    Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
      person: people(:familienmitglied2),
      group: ausserberg_mitglieder,
      beitragskategorie: :adult,
      start_on: date,
      end_on: date + 3.months
    )
    Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
      person: people(:familienmitglied_kind),
      group: ausserberg_mitglieder,
      beitragskategorie: :youth,
      start_on: date,
      end_on: date + 3.months
    )
  end

  context "adult" do
    it "generates positions" do
      expect(positions.size).to eq(5)

      expect(positions[0].name).to eq("sac_fee")
      expect(positions[0].grouping).to eq(:sac_fee)
      expect(positions[0].amount).to eq(100.0)
      expect(positions[0].creditor.to_s).to eq(sac.to_s)
      expect(positions[0].article_number).to eq(config.sac_fee_article_number)
      expect(positions[0].label).to eq("Beitrag Zentralverband")

      expect(positions[1].name).to eq("hut_solidarity_fee")
      expect(positions[1].grouping).to eq(:sac_fee)
      expect(positions[1].amount).to eq(30.0)
      expect(positions[1].creditor.to_s).to eq(sac.to_s)
      expect(positions[1].article_number).to eq(config.hut_solidarity_fee_article_number)
      expect(positions[1].label).to eq("Hütten Solidaritätsbeitrag")

      expect(positions[2].name).to eq("sac_magazine")
      expect(positions[2].grouping).to eq(:sac_fee)
      expect(positions[2].amount).to eq(25.0)
      expect(positions[2].creditor.to_s).to eq(sac.to_s)
      expect(positions[2].article_number).to eq(config.magazine_fee_article_number)
      expect(positions[2].label).to eq("Alpengebühren")

      expect(positions[3].name).to eq("section_fee")
      expect(positions[3].grouping).to eq(nil)
      expect(positions[3].amount).to eq(40.0)
      expect(positions[3].creditor.to_s).to eq(main_section.to_s)
      expect(positions[3].article_number).to eq(config.section_fee_article_number)
      expect(positions[3].label).to eq("Beitrag Sektion SAC Blüemlisalp")

      expect(positions[4].name).to eq("section_fee")
      expect(positions[4].grouping).to eq(nil)
      expect(positions[4].amount).to eq(45.0)
      expect(positions[4].creditor.to_s).to eq(additional_section.to_s)
      expect(positions[4].article_number).to eq(config.section_fee_article_number)
      expect(positions[4].label).to eq("Beitrag Sektion SAC Matterhorn")
    end

    context "with manual_position values nil" do
      let(:manual_positions) { {} }

      it "generates positions with amount 0" do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].grouping).to eq(:sac_fee)
        expect(positions[0].amount).to eq(0.0)
        expect(positions[0].creditor.to_s).to eq(sac.to_s)
        expect(positions[0].article_number).to eq(config.sac_fee_article_number)
        expect(positions[0].label).to eq("Beitrag Zentralverband")

        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].grouping).to eq(:sac_fee)
        expect(positions[1].amount).to eq(0.0)
        expect(positions[1].creditor.to_s).to eq(sac.to_s)
        expect(positions[1].article_number).to eq(config.hut_solidarity_fee_article_number)
        expect(positions[1].label).to eq("Hütten Solidaritätsbeitrag")

        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].grouping).to eq(:sac_fee)
        expect(positions[2].amount).to eq(0.0)
        expect(positions[2].creditor.to_s).to eq(sac.to_s)
        expect(positions[2].article_number).to eq(config.magazine_fee_article_number)
        expect(positions[2].label).to eq("Alpengebühren")

        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].grouping).to eq(nil)
        expect(positions[3].amount).to eq(0.0)
        expect(positions[3].creditor.to_s).to eq(main_section.to_s)
        expect(positions[3].article_number).to eq(config.section_fee_article_number)
        expect(positions[3].label).to eq("Beitrag Sektion SAC Blüemlisalp")

        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].grouping).to eq(nil)
        expect(positions[4].amount).to eq(0.0)
        expect(positions[4].creditor.to_s).to eq(additional_section.to_s)
        expect(positions[4].article_number).to eq(config.section_fee_article_number)
        expect(positions[4].label).to eq("Beitrag Sektion SAC Matterhorn")
      end
    end

    context "with sac_entry_fee present" do
      let(:sac_entry_fee) { 20 }

      it "additionally generates sac_entry_fee position" do
        expect(positions.size).to eq(6)

        expect(positions[5].name).to eq("sac_entry_fee")
        expect(positions[5].amount).to eq(20.0)
      end
    end

    context "with section_entry_fee present" do
      let(:section_entry_fee) { 50 }

      it "additionally generates sac_entry_fee position" do
        expect(positions.size).to eq(6)

        expect(positions[5].name).to eq("section_entry_fee")
        expect(positions[5].amount).to eq(50.0)
      end
    end
  end

  context "family" do
    let(:manual_section_fee_positions) do
      [
        {section_id: main_section.id, fee: 40},
        {section_id: ausserberg_section.id, fee: 42},
        {section_id: additional_section.id, fee: 45}
      ]
    end

    context "main" do
      let(:person) { people(:familienmitglied) }

      it "generates positions" do
        expect(positions.size).to eq(6)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(100.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(30.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(25.0)
        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].label).to eq("Beitrag Sektion SAC Blüemlisalp")
        expect(positions[3].amount).to eq(40.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].label).to eq("Beitrag Sektion SAC Blüemlisalp Ausserberg")
        expect(positions[4].amount).to eq(42.0)
        expect(positions[5].name).to eq("section_fee")
        expect(positions[5].label).to eq("Beitrag Sektion SAC Matterhorn")
        expect(positions[5].amount).to eq(45.0)
      end
    end

    context "second adult" do
      let(:person) { people(:familienmitglied2) }

      it "generates positions" do
        expect(positions.size).to eq(1)

        expect(positions[0].name).to eq("section_fee")
        expect(positions[0].label).to eq("Beitrag Sektion SAC Blüemlisalp Ausserberg")
        expect(positions[0].amount).to eq(42.0)
      end
    end

    context "child" do
      let(:person) { people(:familienmitglied_kind) }

      it "generates positions" do
        expect(positions.size).to eq(1)

        expect(positions[0].name).to eq("section_fee")
        expect(positions[0].label).to eq("Beitrag Sektion SAC Blüemlisalp Ausserberg")
        expect(positions[0].amount).to eq(42.0)
      end
    end

    context "with sac_entry_fee present" do
      let(:sac_entry_fee) { 20 }

      context "main" do
        let(:person) { people(:familienmitglied) }

        it "additionally generates sac_entry_fee position" do
          expect(positions.size).to eq(7)

          expect(positions[6].name).to eq("sac_entry_fee")
          expect(positions[6].label).to eq("Eintrittsgebühr Zentralverband")
          expect(positions[6].amount).to eq(20.0)
        end
      end

      context "second adult" do
        let(:person) { people(:familienmitglied2) }

        it "does not additionally generate sac_entry_fee position" do
          expect(positions.size).to eq(1)

          expect(positions[0].name).to eq("section_fee")
        end
      end

      context "child" do
        let(:person) { people(:familienmitglied_kind) }

        it "does not additionally generate sac_entry_fee position" do
          expect(positions.size).to eq(1)

          expect(positions[0].name).to eq("section_fee")
        end
      end
    end

    context "with section_entry_fee present" do
      let(:section_entry_fee) { 50 }

      context "main" do
        let(:person) { people(:familienmitglied) }

        it "additionally generates section_entry_fee position" do
          expect(positions.size).to eq(7)

          expect(positions[6].name).to eq("section_entry_fee")
          expect(positions[6].label).to eq("Eintrittsgebühr SAC Blüemlisalp")
          expect(positions[6].amount).to eq(50.0)
        end
      end

      context "second adult" do
        let(:person) { people(:familienmitglied2) }

        it "does not additionally generate section_entry_fee position" do
          expect(positions.size).to eq(1)

          expect(positions[0].name).to eq("section_fee")
        end
      end

      context "child" do
        let(:person) { people(:familienmitglied_kind) }

        it "does not additionally generate section_entry_fee position" do
          expect(positions.size).to eq(1)

          expect(positions[0].name).to eq("section_fee")
        end
      end
    end
  end

  context "living abroad" do
    before do
      person.update!(country: "DE", zip_code: 80000)
      context.fetch_section(additional_section).bulletin_postage_abroad = 0
    end

    context "family main" do
      let(:person) { people(:familienmitglied) }

      it "generates positions" do
        expect(positions.size).to eq(9)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(100.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(30.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(25.0)
        expect(positions[3].name).to eq("sac_magazine_postage_abroad")
        expect(positions[3].amount).to eq(35.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].label).to eq("Beitrag Sektion SAC Blüemlisalp")
        expect(positions[4].amount).to eq(40.0)
        expect(positions[5].name).to eq("section_bulletin_postage_abroad")
        expect(positions[5].label).to eq("Porto Bulletin SAC Blüemlisalp")
        expect(positions[5].amount).to eq(13.0)
        expect(positions[6].name).to eq("section_fee")
        expect(positions[6].label).to eq("Beitrag Sektion SAC Blüemlisalp Ausserberg")
        expect(positions[6].amount).to eq(42.0)
        expect(positions[7].name).to eq("section_bulletin_postage_abroad")
        expect(positions[7].amount).to eq(15.0)
        expect(positions[8].name).to eq("section_fee")
        expect(positions[8].label).to eq("Beitrag Sektion SAC Matterhorn")
        expect(positions[8].amount).to eq(45.0)
      end

      context "without subscription" do
        before do
          magazine_list.subscriptions.create!(subscriber: person, excluded: true)
        end

        it "generates positions" do
          expect(positions.size).to eq(8)

          expect(positions[0].name).to eq("sac_fee")
          expect(positions[0].amount).to eq(100.0)
          expect(positions[1].name).to eq("hut_solidarity_fee")
          expect(positions[1].amount).to eq(30.0)
          expect(positions[2].name).to eq("sac_magazine")
          expect(positions[2].amount).to eq(25.0)
          expect(positions[3].name).to eq("section_fee")
          expect(positions[3].label).to eq("Beitrag Sektion SAC Blüemlisalp")
          expect(positions[3].amount).to eq(40.0)
          expect(positions[4].name).to eq("section_bulletin_postage_abroad")
          expect(positions[4].label).to eq("Porto Bulletin SAC Blüemlisalp")
          expect(positions[4].amount).to eq(13.0)
          expect(positions[5].name).to eq("section_fee")
          expect(positions[5].label).to eq("Beitrag Sektion SAC Blüemlisalp Ausserberg")
          expect(positions[5].amount).to eq(42.0)
          expect(positions[6].name).to eq("section_bulletin_postage_abroad")
          expect(positions[6].label).to eq("Porto Bulletin SAC Blüemlisalp Ausserberg")
          expect(positions[6].amount).to eq(15.0)
          expect(positions[7].name).to eq("section_fee")
          expect(positions[7].label).to eq("Beitrag Sektion SAC Matterhorn")
          expect(positions[7].amount).to eq(45.0)
        end
      end

      context "without section bulletin subscription in bluemlisalp" do
        before do
          section_bulletin_bluemlisalp.subscriptions.create!(subscriber: person, excluded: true)
        end

        it "generates positions" do
          expect(positions.size).to eq(8)

          expect(positions[0].name).to eq("sac_fee")
          expect(positions[0].amount).to eq(100.0)
          expect(positions[1].name).to eq("hut_solidarity_fee")
          expect(positions[1].amount).to eq(30.0)
          expect(positions[2].name).to eq("sac_magazine")
          expect(positions[2].amount).to eq(25.0)
          expect(positions[3].name).to eq("sac_magazine_postage_abroad")
          expect(positions[3].amount).to eq(35.0)
          expect(positions[4].name).to eq("section_fee")
          expect(positions[4].label).to eq("Beitrag Sektion SAC Blüemlisalp")
          expect(positions[4].amount).to eq(40.0)
          expect(positions[5].name).to eq("section_fee")
          expect(positions[5].label).to eq("Beitrag Sektion SAC Blüemlisalp Ausserberg")
          expect(positions[5].amount).to eq(42.0)
          expect(positions[6].name).to eq("section_bulletin_postage_abroad")
          expect(positions[6].label).to eq("Porto Bulletin SAC Blüemlisalp Ausserberg")
          expect(positions[6].amount).to eq(15.0)
          expect(positions[7].name).to eq("section_fee")
          expect(positions[7].label).to eq("Beitrag Sektion SAC Matterhorn")
          expect(positions[7].amount).to eq(45.0)
        end
      end
    end

    context "child" do
      let(:person) { people(:familienmitglied_kind) }

      it "generates positions" do
        expect(positions.size).to eq(2)

        expect(positions[0].name).to eq("section_fee")
        expect(positions[0].amount).to eq(42.0)
        expect(positions[1].name).to eq("section_bulletin_postage_abroad")
        expect(positions[1].label).to eq("Porto Bulletin SAC Blüemlisalp Ausserberg")
        expect(positions[1].amount).to eq(15.0)
      end
    end
  end

  context "with huts" do
    let(:funktionaere) {
      main_section.children.find { |child|
     child.type == "Group::SektionsFunktionaere" # rubocop:todo Layout/IndentationWidth
      }
    }

    before do
      huetten = Group::SektionsClubhuetten.create!(parent: funktionaere)
      Group::SektionsClubhuette.create!(parent: huetten, name: "Blüemlisalphütte")
    end

    it "generates hut solidarity fee with hut" do
      expect(positions[1].name).to eq("hut_solidarity_fee")
      expect(positions[1].amount).to eq(30.0)
    end

    context "in ortsgruppe" do
      before do
        person.roles.where(group: groups(:bluemlisalp_mitglieder))
          .update_all(group_id: ausserberg_mitglieder.id)
      end

      it "generates hut solidarity fee with hut" do
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(30.0)
      end
    end
  end

  context "new additional section" do
    let(:memberships) do
      [member.membership_from_role(member.neuanmeldung_nv_zusatzsektion_roles.find { |r|
        r.layer_group.id == group.layer_group.id
      })]
    end

    let(:person) { Fabricate(:person) }
    let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }
    let(:beitragskategorie) { :adult }

    def create_neuanmeldung_zusatzsektion
      Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.create!(
        person: person,
        group: group,
        beitragskategorie: beitragskategorie,
        start_on: date
      )
    end

    it "generates positions" do
      create_neuanmeldung_zusatzsektion
      expect(positions.size).to eq(1)

      expect(positions[0].name).to eq("section_fee")
      expect(positions[0].amount).to eq(40.0)
    end

    context "for family child with individual youth zusatzmitgliedschaft" do
      let(:person) { people(:familienmitglied_kind) }
      let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv) }
      let(:beitragskategorie) { :youth }

      before do
        Group::SektionsMitglieder::MitgliedZusatzsektion.with_inactive.where(person: person,
          beitragskategorie: :youth).delete_all
        create_neuanmeldung_zusatzsektion
      end

      it "generates positions" do
        expect(positions.size).to eq(1)

        expect(positions[0].name).to eq("section_fee")
        expect(positions[0].amount).to eq(42.0)
      end
    end

    context "living abroad" do
      before do
        create_neuanmeldung_zusatzsektion
        person.update!(country: "DE", zip_code: 80000)
        context.fetch_section(additional_section).bulletin_postage_abroad = 0
      end

      it "generates positions" do
        expect(positions.size).to eq(2)

        expect(positions[0].name).to eq("section_fee")
        expect(positions[0].amount).to eq(40.0)
        expect(positions[1].name).to eq("section_bulletin_postage_abroad")
        expect(positions[1].label).to eq("Porto Bulletin SAC Blüemlisalp")
        expect(positions[1].amount).to eq(13.0)
      end
    end
  end
end
