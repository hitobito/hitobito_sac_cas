# frozen_string_literal: true

require "spec_helper"

describe Invoices::SacMemberships::PositionGenerator do
  let(:sac) { Group.root }
  let(:person) { people(:mitglied) }
  let(:date) { Date.new(2023, 1, 1) }
  let(:context) { Invoices::SacMemberships::Context.new(date) }
  let(:member) { Invoices::SacMemberships::Member.new(context.people_with_membership_years.find(person.id), context) }
  let(:config) { context.config }
  let(:main_section) { groups(:bluemlisalp) }
  let(:additional_section) { groups(:matterhorn) }
  let(:memberships) { member.active_memberships }
  let(:new_entry) { false }
  let(:positions) { described_class.new(member).generate(memberships, new_entry: new_entry) }
  let(:magazine_list) { mailing_lists(:sac_magazine) }

  before do
    SacMembershipConfig.update_all(valid_from: 2020)
    SacSectionMembershipConfig.update_all(valid_from: 2020)
    Role.update_all(delete_on: date + 3.months)
  end

  context "adult" do
    it "generates positions" do
      expect(positions.size).to eq(5)

      expect(positions[0].name).to eq("sac_fee")
      expect(positions[0].group).to eq(:sac_fee)
      expect(positions[0].amount).to eq(40.0)
      expect(positions[0].creditor.to_s).to eq(sac.to_s)
      expect(positions[0].article_number).to eq(config.sac_fee_article_number)

      expect(positions[1].name).to eq("hut_solidarity_fee")
      expect(positions[1].group).to eq(:sac_fee)
      expect(positions[1].amount).to eq(20.0)
      expect(positions[1].creditor.to_s).to eq(sac.to_s)
      expect(positions[1].article_number).to eq(config.hut_solidarity_fee_article_number)

      expect(positions[2].name).to eq("sac_magazine")
      expect(positions[2].group).to eq(:sac_fee)
      expect(positions[2].amount).to eq(25.0)
      expect(positions[2].creditor.to_s).to eq(sac.to_s)
      expect(positions[2].article_number).to eq(config.magazine_fee_article_number)

      expect(positions[3].name).to eq("section_fee")
      expect(positions[3].group).to eq(nil)
      expect(positions[3].amount).to eq(42.0)
      expect(positions[3].creditor.to_s).to eq(main_section.to_s)
      expect(positions[3].article_number).to eq(config.section_fee_article_number)

      expect(positions[4].name).to eq("section_fee")
      expect(positions[4].group).to eq(nil)
      expect(positions[4].amount).to eq(56.0)
      expect(positions[4].creditor.to_s).to eq(additional_section.to_s)
      expect(positions[4].article_number).to eq(config.section_fee_article_number)
    end

    context "with custom discount" do
      let(:positions) { described_class.new(member, custom_discount: 50).generate(memberships, new_entry: new_entry) }

      it "generates positions" do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].group).to eq(:sac_fee)
        expect(positions[0].amount).to eq(20.0)
        expect(positions[0].creditor.to_s).to eq(sac.to_s)
        expect(positions[0].article_number).to eq(config.sac_fee_article_number)

        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].group).to eq(:sac_fee)
        expect(positions[1].amount).to eq(10.0)
        expect(positions[1].creditor.to_s).to eq(sac.to_s)
        expect(positions[1].article_number).to eq(config.hut_solidarity_fee_article_number)

        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].group).to eq(:sac_fee)
        expect(positions[2].amount).to eq(12.5)
        expect(positions[2].creditor.to_s).to eq(sac.to_s)
        expect(positions[2].article_number).to eq(config.magazine_fee_article_number)

        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].group).to eq(nil)
        expect(positions[3].amount).to eq(21.0)
        expect(positions[3].creditor.to_s).to eq(main_section.to_s)
        expect(positions[3].article_number).to eq(config.section_fee_article_number)

        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].group).to eq(nil)
        expect(positions[4].amount).to eq(28.0)
        expect(positions[4].creditor.to_s).to eq(additional_section.to_s)
        expect(positions[4].article_number).to eq(config.section_fee_article_number)
      end
    end
  end

  context "family" do
    context "main" do
      let(:person) { people(:familienmitglied) }

      it "generates positions" do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(50.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(20.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(25.0)
        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].amount).to eq(84.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].amount).to eq(88.0)
      end
    end

    context "second adult" do
      let(:person) { people(:familienmitglied2) }

      it "generates positions" do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(0.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(0.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(0.0)
        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].amount).to eq(0.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].amount).to eq(0.0)
      end
    end

    context "child" do
      let(:person) { people(:familienmitglied_kind) }

      it "generates positions" do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(0.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(0.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(0.0)
        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].amount).to eq(0.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].amount).to eq(0.0)
      end
    end
  end

  context "living abroad" do
    before do
      person.update!(country: "DE")
      context.fetch_section(additional_section).bulletin_postage_abroad = 0
    end

    context "family main" do
      let(:person) { people(:familienmitglied) }

      it "generates positions" do
        expect(positions.size).to eq(7)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(50.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(20.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(25.0)
        expect(positions[3].name).to eq("sac_magazine_postage_abroad")
        expect(positions[3].amount).to eq(10.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].amount).to eq(84.0)
        expect(positions[5].name).to eq("section_bulletin_postage_abroad")
        expect(positions[5].amount).to eq(13.0)
        expect(positions[6].name).to eq("section_fee")
        expect(positions[6].amount).to eq(88.0)
      end

      context "without subscription" do
        before do
          magazine_list.exclude_person(person)
        end

        it "generates positions" do
          expect(positions.size).to eq(6)

          expect(positions[0].name).to eq("sac_fee")
          expect(positions[0].amount).to eq(50.0)
          expect(positions[1].name).to eq("hut_solidarity_fee")
          expect(positions[1].amount).to eq(20.0)
          expect(positions[2].name).to eq("sac_magazine")
          expect(positions[2].amount).to eq(25.0)
          expect(positions[3].name).to eq("section_fee")
          expect(positions[3].amount).to eq(84.0)
          expect(positions[4].name).to eq("section_bulletin_postage_abroad")
          expect(positions[4].amount).to eq(13.0)
          expect(positions[5].name).to eq("section_fee")
          expect(positions[5].amount).to eq(88.0)
        end
      end
    end

    context "child" do
      let(:person) { people(:familienmitglied_kind) }

      it "generates positions" do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(0.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(0.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(0.0)
        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].amount).to eq(0.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].amount).to eq(0.0)
      end
    end

    context "middle of the year" do
      let(:date) { Date.new(2023, 8, 15) }
      let(:person) { people(:familienmitglied) }

      before do
        Role.update_all(delete_on: date.end_of_year)
      end

      it "generates discounted positions" do
        expect(positions.size).to eq(7)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(25.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(10.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(12.5)
        expect(positions[3].name).to eq("sac_magazine_postage_abroad")
        expect(positions[3].amount).to eq(5.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].amount).to eq(42.0)
        expect(positions[5].name).to eq("section_bulletin_postage_abroad")
        expect(positions[5].amount).to eq(6.5)
        expect(positions[6].name).to eq("section_fee")
        expect(positions[6].amount).to eq(44.0)
      end
    end

    context "end of the year" do
      let(:date) { Date.new(2023, 11, 15) }
      let(:person) { people(:familienmitglied) }

      before do
        Role.update_all(delete_on: date.end_of_year)
      end

      it "generates discounted positions" do
        expect(positions.size).to eq(7)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(0.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(0.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(0.0)
        expect(positions[3].name).to eq("sac_magazine_postage_abroad")
        expect(positions[3].amount).to eq(0.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].amount).to eq(0.0)
        expect(positions[5].name).to eq("section_bulletin_postage_abroad")
        expect(positions[5].amount).to eq(0.0)
        expect(positions[6].name).to eq("section_fee")
        expect(positions[6].amount).to eq(0.0)
      end
    end
  end

  context "with huts" do
    let(:funktionaere) { main_section.children.find { |child| child.type == "Group::SektionsFunktionaere" } }

    before do
      huetten = Group::SektionsClubhuetten.create!(parent: funktionaere)
      Group::SektionsClubhuette.create!(parent: huetten, name: "Blüemlisalphütte")
    end

    it "generates hut solidarity fee with hut" do
      expect(positions[1].name).to eq("hut_solidarity_fee")
      expect(positions[1].amount).to eq(10.0)
    end

    context "in ortsgruppe" do
      before do
        person.roles.where(group: groups(:bluemlisalp_mitglieder))
          .update_all(group_id: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder).id)
      end

      it "generates hut solidarity fee with hut" do
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(10.0)
      end
    end
  end

  context "honorary member sac" do
    before do
      group = Group::Ehrenmitglieder.create!(name: "Ehrenmitglieder", parent: groups(:root))
      Group::Ehrenmitglieder::Ehrenmitglied.create!(
        person: person,
        group: group,
        created_at: "2022-08-01"
      )
    end

    it "generates positions" do
      expect(positions.size).to eq(5)

      expect(positions[0].name).to eq("sac_fee")
      expect(positions[0].amount).to eq(0.0)
      expect(positions[0].creditor.to_s).to eq(sac.to_s)
      expect(positions[0]).not_to be_section_pays

      expect(positions[1].name).to eq("hut_solidarity_fee")
      expect(positions[1].amount).to eq(0.0)
      expect(positions[1].creditor.to_s).to eq(sac.to_s)
      expect(positions[1]).not_to be_section_pays

      expect(positions[2].name).to eq("sac_magazine")
      expect(positions[2].amount).to eq(0.0)
      expect(positions[2].creditor.to_s).to eq(sac.to_s)
      expect(positions[2]).not_to be_section_pays

      expect(positions[3].name).to eq("section_fee")
      expect(positions[3].amount).to eq(0.0)
      expect(positions[3].creditor.to_s).to eq(main_section.to_s)
      expect(positions[3]).not_to be_section_pays

      expect(positions[4].name).to eq("section_fee")
      expect(positions[4].amount).to eq(0.0)
      expect(positions[4].creditor.to_s).to eq(additional_section.to_s)
      expect(positions[4]).not_to be_section_pays
    end

    context "and honorary member section" do
      before do
        Group::SektionsMitglieder::Ehrenmitglied.create!(
          person: person,
          group: groups(:bluemlisalp_mitglieder),
          created_at: "2022-08-01"
        )
      end

      it "generates positions" do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(0.0)
        expect(positions[0].creditor.to_s).to eq(sac.to_s)
        expect(positions[0]).not_to be_section_pays

        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].group).to eq(:sac_fee)
        expect(positions[1].amount).to eq(0.0)
        expect(positions[1].creditor.to_s).to eq(sac.to_s)
        expect(positions[1]).not_to be_section_pays

        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(0.0)
        expect(positions[2].creditor.to_s).to eq(sac.to_s)
        expect(positions[2]).not_to be_section_pays

        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].amount).to eq(0.0)
        expect(positions[3].creditor.to_s).to eq(main_section.to_s)
        expect(positions[3]).not_to be_section_pays

        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].amount).to eq(0.0)
        expect(positions[4].creditor.to_s).to eq(additional_section.to_s)
        expect(positions[4]).not_to be_section_pays
      end
    end
  end

  context "honorary member section" do
    before do
      Group::SektionsMitglieder::Ehrenmitglied.create!(
        person: person,
        group: groups(:bluemlisalp_mitglieder),
        created_at: "2022-08-01"
      )
    end

    it "generates positions" do
      expect(positions.size).to eq(5)

      expect(positions[0].name).to eq("sac_fee")
      expect(positions[0].group).to eq(:sac_fee)
      expect(positions[0].amount).to eq(40.0)
      expect(positions[0].creditor.to_s).to eq(sac.to_s)
      expect(positions[0].article_number).to eq(config.sac_fee_article_number)
      expect(positions[0]).to be_section_pays

      expect(positions[1].name).to eq("hut_solidarity_fee")
      expect(positions[1].group).to eq(:sac_fee)
      expect(positions[1].amount).to eq(20.0)
      expect(positions[1].creditor.to_s).to eq(sac.to_s)
      expect(positions[1].article_number).to eq(config.hut_solidarity_fee_article_number)
      expect(positions[1]).to be_section_pays

      expect(positions[2].name).to eq("sac_magazine")
      expect(positions[2].group).to eq(:sac_fee)
      expect(positions[2].amount).to eq(25.0)
      expect(positions[2].creditor.to_s).to eq(sac.to_s)
      expect(positions[2].article_number).to eq(config.magazine_fee_article_number)
      expect(positions[2]).to be_section_pays

      expect(positions[3].name).to eq("section_fee")
      expect(positions[3].group).to eq(nil)
      expect(positions[3].amount).to eq(0.0)
      expect(positions[3].creditor.to_s).to eq(main_section.to_s)
      expect(positions[3].article_number).to eq(config.section_fee_article_number)
      expect(positions[3]).not_to be_section_pays

      expect(positions[4].name).to eq("section_fee")
      expect(positions[4].group).to eq(nil)
      expect(positions[4].amount).to eq(56.0)
      expect(positions[4].creditor.to_s).to eq(additional_section.to_s)
      expect(positions[4].article_number).to eq(config.section_fee_article_number)
      expect(positions[4]).not_to be_section_pays
    end
  end

  context "benefited member section" do
    before do
      Group::SektionsMitglieder::Beguenstigt.create!(
        person: person,
        group: groups(:bluemlisalp_mitglieder),
        created_at: "2022-08-01"
      )
    end

    it "generates positions" do
      context.fetch_section(main_section).config.sac_fee_exemption_for_benefited_members = false
      context.fetch_section(main_section).config.section_fee_exemption_for_benefited_members = true

      expect(positions.size).to eq(5)

      expect(positions[0].name).to eq("sac_fee")
      expect(positions[0].group).to eq(:sac_fee)
      expect(positions[0].amount).to eq(40.0)
      expect(positions[0].creditor.to_s).to eq(sac.to_s)
      expect(positions[0].article_number).to eq(config.sac_fee_article_number)
      expect(positions[0]).not_to be_section_pays

      expect(positions[1].name).to eq("hut_solidarity_fee")
      expect(positions[1].group).to eq(:sac_fee)
      expect(positions[1].amount).to eq(20.0)
      expect(positions[1].creditor.to_s).to eq(sac.to_s)
      expect(positions[1].article_number).to eq(config.hut_solidarity_fee_article_number)
      expect(positions[1]).not_to be_section_pays

      expect(positions[2].name).to eq("sac_magazine")
      expect(positions[2].group).to eq(:sac_fee)
      expect(positions[2].amount).to eq(25.0)
      expect(positions[2].creditor.to_s).to eq(sac.to_s)
      expect(positions[2].article_number).to eq(config.magazine_fee_article_number)
      expect(positions[2]).not_to be_section_pays

      expect(positions[3].name).to eq("section_fee")
      expect(positions[3].group).to eq(nil)
      expect(positions[3].amount).to eq(0.0)
      expect(positions[3].creditor.to_s).to eq(main_section.to_s)
      expect(positions[3].article_number).to eq(config.section_fee_article_number)
      expect(positions[3]).not_to be_section_pays

      expect(positions[4].name).to eq("section_fee")
      expect(positions[4].group).to eq(nil)
      expect(positions[4].amount).to eq(56.0)
      expect(positions[4].creditor.to_s).to eq(additional_section.to_s)
      expect(positions[4].article_number).to eq(config.section_fee_article_number)
      expect(positions[4]).not_to be_section_pays
    end

    it "generates positions with sac exemption" do
      context.fetch_section(main_section).config.sac_fee_exemption_for_benefited_members = true
      context.fetch_section(main_section).config.section_fee_exemption_for_benefited_members = false

      expect(positions.size).to eq(5)

      expect(positions[0].name).to eq("sac_fee")
      expect(positions[0].group).to eq(:sac_fee)
      expect(positions[0].amount).to eq(40.0)
      expect(positions[0].creditor.to_s).to eq(sac.to_s)
      expect(positions[0].article_number).to eq(config.sac_fee_article_number)
      expect(positions[0]).to be_section_pays

      expect(positions[1].name).to eq("hut_solidarity_fee")
      expect(positions[1].group).to eq(:sac_fee)
      expect(positions[1].amount).to eq(20.0)
      expect(positions[1].creditor.to_s).to eq(sac.to_s)
      expect(positions[1].article_number).to eq(config.hut_solidarity_fee_article_number)
      expect(positions[1]).to be_section_pays

      expect(positions[2].name).to eq("sac_magazine")
      expect(positions[2].group).to eq(:sac_fee)
      expect(positions[2].amount).to eq(25.0)
      expect(positions[2].creditor.to_s).to eq(sac.to_s)
      expect(positions[2].article_number).to eq(config.magazine_fee_article_number)
      expect(positions[2]).to be_section_pays

      expect(positions[3].name).to eq("section_fee")
      expect(positions[3].group).to eq(nil)
      expect(positions[3].amount).to eq(42.0)
      expect(positions[3].creditor.to_s).to eq(main_section.to_s)
      expect(positions[3].article_number).to eq(config.section_fee_article_number)
      expect(positions[3]).not_to be_section_pays

      expect(positions[4].name).to eq("section_fee")
      expect(positions[4].group).to eq(nil)
      expect(positions[4].amount).to eq(56.0)
      expect(positions[4].creditor.to_s).to eq(additional_section.to_s)
      expect(positions[4].article_number).to eq(config.section_fee_article_number)
      expect(positions[4]).not_to be_section_pays
    end
  end

  context "with sac reduction" do
    # 50 years of membership gives reduction on sac fees
    before do
      roles(:mitglied).update!(created_at: date - 52.years)
    end

    it "generates positions" do
      expect(positions.size).to eq(5)

      expect(positions[0].name).to eq("sac_fee")
      expect(positions[0].amount).to eq(30.0)
      expect(positions[1].name).to eq("hut_solidarity_fee")
      expect(positions[1].amount).to eq(20.0)
      expect(positions[2].name).to eq("sac_magazine")
      expect(positions[2].amount).to eq(25.0)
      expect(positions[3].name).to eq("section_fee")
      expect(positions[3].amount).to eq(42.0)
      expect(positions[4].name).to eq("section_fee")
      expect(positions[4].amount).to eq(41.0)
    end
  end

  context "with section membership years reduction" do
    before do
      # 25 years of membership gives reduction on section fees
      roles(:mitglied).update!(created_at: date - 30.years)
      person.update(birthday: "1955-03-23")
      context.fetch_section(main_section).reduction_required_age = 0
    end

    context "first year with reduction" do
      before do
        roles(:mitglied).update!(created_at: Date.new(date.year - 25, 1, 1))
      end

      it "generates positions with reduction" do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(40.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(20.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(25.0)
        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].amount).to eq(32.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].amount).to eq(56.0)
      end
    end

    context "first year with reduction, with end of year entry" do
      before do
        roles(:mitglied).update!(created_at: Date.new(date.year - 25, 12, 31))
      end

      it "generates positions without reduction" do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(40.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(20.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(25.0)
        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].amount).to eq(32.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].amount).to eq(56.0)
      end
    end

    context "last year without reduction" do
      before do
        # because days are divided by 365, people with an entry date before january 9th
        # will have 25 years already one year earlier
        roles(:mitglied).update!(created_at: Date.new(date.year - 24, 1, 9))
      end

      it "generates positions without reduction" do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(40.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(20.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(25.0)
        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].amount).to eq(42.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].amount).to eq(56.0)
      end
    end

    context "middle of the year" do
      let(:date) { Date.new(2023, 7, 1) }

      before do
        Role.update_all(delete_on: date.end_of_year)
      end

      it "generates discounted positions" do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(20.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(10.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(12.5)
        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].amount).to eq(16.0)
        expect(positions[4].name).to eq("section_fee")
        expect(positions[4].amount).to eq(20.5)
      end
    end
  end

  context "with section age reduction" do
    before do
      person.update(birthday: "1955-03-23")
      context.fetch_section(main_section).reduction_required_membership_years = nil
    end

    it "generates positions" do
      expect(positions.size).to eq(5)

      expect(positions[0].name).to eq("sac_fee")
      expect(positions[0].amount).to eq(40.0)
      expect(positions[1].name).to eq("hut_solidarity_fee")
      expect(positions[1].amount).to eq(20.0)
      expect(positions[2].name).to eq("sac_magazine")
      expect(positions[2].amount).to eq(25.0)
      expect(positions[3].name).to eq("section_fee")
      expect(positions[3].amount).to eq(32.0)
      expect(positions[4].name).to eq("section_fee")
      expect(positions[4].amount).to eq(56.0)
    end
  end

  context "new entry" do
    let(:memberships) { [member.membership_from_role(member.neuanmeldung_nv_stammsektion_roles.first, main: true)] }
    let(:new_entry) { true }

    context "without neuanmeldung" do
      let(:memberships) { [] }

      it "generates no positions" do
        expect(positions.size).to eq(0)
      end
    end

    context "with neuanmeldung" do
      let(:person) { Fabricate(:person) }

      before do
        Group::SektionsNeuanmeldungenNv::Neuanmeldung.create!(
          person: person,
          group: groups(:bluemlisalp_neuanmeldungen_nv),
          created_at: date
        )
      end

      it "generates positions" do
        expect(positions.size).to eq(6)

        expect(positions[0].name).to eq("sac_fee")
        expect(positions[0].amount).to eq(40.0)
        expect(positions[1].name).to eq("hut_solidarity_fee")
        expect(positions[1].amount).to eq(20.0)
        expect(positions[2].name).to eq("sac_magazine")
        expect(positions[2].amount).to eq(25.0)

        expect(positions[3].name).to eq("section_fee")
        expect(positions[3].amount).to eq(42.0)

        expect(positions[4].name).to eq("sac_entry_fee")
        expect(positions[4].amount).to eq(10.0)
        expect(positions[4].group).to eq(nil)
        expect(positions[4].creditor.to_s).to eq(sac.to_s)
        expect(positions[4].article_number).to eq(config.sac_entry_fee_article_number)

        expect(positions[5].name).to eq("section_entry_fee")
        expect(positions[5].amount).to eq(10.0)
        expect(positions[5].group).to eq(nil)
        expect(positions[5].creditor.to_s).to eq(main_section.to_s)
        expect(positions[5].article_number).to eq(config.section_entry_fee_article_number)
      end
    end
  end

  context "new additional section" do
    let(:memberships) do
      [member.membership_from_role(member.neuanmeldung_nv_zusatzsektion_roles.find { |r| r.layer_group.id == groups(:bluemlisalp).id })]
    end

    let(:person) { Fabricate(:person) }

    before do
      Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.create!(
        person: person,
        group: groups(:bluemlisalp_neuanmeldungen_nv),
        created_at: date
      )
    end

    it "generates positions" do
      expect(positions.size).to eq(1)

      expect(positions[0].name).to eq("section_fee")
      expect(positions[0].amount).to eq(42.0)
    end

    context "living abroad" do
      before do
        person.update!(country: "DE")
        context.fetch_section(additional_section).bulletin_postage_abroad = 0
      end

      it "generates positions" do
        expect(positions.size).to eq(2)

        expect(positions[0].name).to eq("section_fee")
        expect(positions[0].amount).to eq(42.0)
        expect(positions[1].name).to eq("section_bulletin_postage_abroad")
        expect(positions[1].amount).to eq(13.0)
      end
    end
  end
end
