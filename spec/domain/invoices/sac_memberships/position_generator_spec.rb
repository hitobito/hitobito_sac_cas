# frozen_string_literal: true

require 'spec_helper'

describe Invoices::SacMemberships::PositionGenerator do

  let(:sac) { Group.root }
  let(:model) { people(:mitglied) }
  let(:date) { Date.new(2023, 1, 1) }
  let(:context) { Invoices::SacMemberships::Context.new(date) }
  let(:person) { Invoices::SacMemberships::Person.new(Person.with_membership_years('people.*', date).find_by(id: model.id), context) }
  let(:config) { context.config }
  let(:main_section) { groups(:bluemlisalp) }
  let(:additional_section) { groups(:matterhorn) }
  let(:positions) { described_class.new(person).membership_positions }
  let(:magazine_list) { mailing_lists(:sac_magazine) }

  before do
    SacMembershipConfig.update_all(valid_from: 2020)
    SacSectionMembershipConfig.update_all(valid_from: 2020)
    Role.update_all(delete_on: date.end_of_year)
  end

  context 'adult' do
    it 'generates positions' do
      expect(positions.size).to eq(6)

      expect(positions[0].name).to eq('section_fee')
      expect(positions[0].group).to eq(nil)
      expect(positions[0].amount).to eq(42.0)
      expect(positions[0].debitor).to eq(person)
      expect(positions[0].creditor.to_s).to eq(main_section.to_s)
      expect(positions[0].article_number).to eq(config.section_fee_article_number)

      expect(positions[1].name).to eq('sac_fee')
      expect(positions[1].group).to eq(:sac_fee)
      expect(positions[1].amount).to eq(40.0)
      expect(positions[1].debitor).to eq(person)
      expect(positions[1].creditor.to_s).to eq(sac.to_s)
      expect(positions[1].article_number).to eq(config.sac_fee_article_number)

      expect(positions[2].name).to eq('hut_solidarity_fee')
      expect(positions[2].group).to eq(:sac_fee)
      expect(positions[2].amount).to eq(20.0)
      expect(positions[2].debitor).to eq(person)
      expect(positions[2].creditor.to_s).to eq(sac.to_s)
      expect(positions[2].article_number).to eq(config.hut_solidarity_fee_article_number)

      expect(positions[3].name).to eq('sac_magazine')
      expect(positions[3].group).to eq(:sac_fee)
      expect(positions[3].amount).to eq(25.0)
      expect(positions[3].debitor).to eq(person)
      expect(positions[3].creditor.to_s).to eq(sac.to_s)
      expect(positions[3].article_number).to eq(config.magazine_fee_article_number)

      expect(positions[4].name).to eq('service_fee')
      expect(positions[4].group).to eq(nil)
      expect(positions[4].amount).to eq(1.0)
      expect(positions[4].debitor.to_s).to eq(main_section.to_s)
      expect(positions[4].creditor.to_s).to eq(sac.to_s)
      expect(positions[4].article_number).to eq(config.service_fee_article_number)

      expect(positions[5].name).to eq('section_fee')
      expect(positions[5].group).to eq(nil)
      expect(positions[5].amount).to eq(56.0)
      expect(positions[5].debitor).to eq(person)
      expect(positions[5].creditor.to_s).to eq(additional_section.to_s)
      expect(positions[5].article_number).to eq(config.section_fee_article_number)
    end
  end

  context 'family' do
    context 'main' do
      let(:model) { people(:familienmitglied) }

      it 'generates positions' do
        expect(positions.size).to eq(6)

        expect(positions[0].name).to eq('section_fee')
        expect(positions[0].amount).to eq(84.0)
        expect(positions[1].name).to eq('sac_fee')
        expect(positions[1].amount).to eq(50.0)
        expect(positions[2].name).to eq('hut_solidarity_fee')
        expect(positions[2].amount).to eq(20.0)
        expect(positions[3].name).to eq('sac_magazine')
        expect(positions[3].amount).to eq(25.0)
        expect(positions[4].name).to eq('service_fee')
        expect(positions[4].amount).to eq(1.0)
        expect(positions[5].name).to eq('section_fee')
        expect(positions[5].amount).to eq(88.0)
      end
    end

    context 'second adult' do
      let(:model) { people(:familienmitglied2) }

      it 'generates positions' do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq('section_fee')
        expect(positions[0].amount).to eq(0.0)
        expect(positions[1].name).to eq('sac_fee')
        expect(positions[1].amount).to eq(0.0)
        expect(positions[2].name).to eq('hut_solidarity_fee')
        expect(positions[2].amount).to eq(0.0)
        expect(positions[3].name).to eq('sac_magazine')
        expect(positions[3].amount).to eq(0.0)
        expect(positions[4].name).to eq('section_fee')
        expect(positions[4].amount).to eq(0.0)
      end
    end

    context 'child' do
      let(:model) { people(:familienmitglied_kind) }

      it 'generates positions' do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq('section_fee')
        expect(positions[0].amount).to eq(0.0)
        expect(positions[1].name).to eq('sac_fee')
        expect(positions[1].amount).to eq(0.0)
        expect(positions[2].name).to eq('hut_solidarity_fee')
        expect(positions[2].amount).to eq(0.0)
        expect(positions[3].name).to eq('sac_magazine')
        expect(positions[3].amount).to eq(0.0)
        expect(positions[4].name).to eq('section_fee')
        expect(positions[4].amount).to eq(0.0)
      end
    end
  end

  context 'living abroad' do
    before do
      model.update!(country: 'DE')
      context.fetch_section(additional_section).bulletin_postage_abroad = 0
    end

    context 'family main' do
      let(:model) { people(:familienmitglied) }

      it 'generates positions' do
        expect(positions.size).to eq(8)

        expect(positions[0].name).to eq('section_fee')
        expect(positions[0].amount).to eq(84.0)
        expect(positions[1].name).to eq('section_bulletin_postage_abroad')
        expect(positions[1].amount).to eq(13.0)
        expect(positions[2].name).to eq('sac_fee')
        expect(positions[2].amount).to eq(50.0)
        expect(positions[3].name).to eq('hut_solidarity_fee')
        expect(positions[3].amount).to eq(20.0)
        expect(positions[4].name).to eq('sac_magazine')
        expect(positions[4].amount).to eq(25.0)
        expect(positions[5].name).to eq('sac_magazine_postage_abroad')
        expect(positions[5].amount).to eq(10.0)
        expect(positions[6].name).to eq('service_fee')
        expect(positions[6].amount).to eq(1.0)
        expect(positions[7].name).to eq('section_fee')
        expect(positions[7].amount).to eq(88.0)
      end

      context 'without subscription' do
        before do
          magazine_list.exclude_person(model)
        end

        it 'generates positions' do
          expect(positions.size).to eq(7)

          expect(positions[0].name).to eq('section_fee')
          expect(positions[0].amount).to eq(84.0)
          expect(positions[1].name).to eq('section_bulletin_postage_abroad')
          expect(positions[1].amount).to eq(13.0)
          expect(positions[2].name).to eq('sac_fee')
          expect(positions[2].amount).to eq(50.0)
          expect(positions[3].name).to eq('hut_solidarity_fee')
          expect(positions[3].amount).to eq(20.0)
          expect(positions[4].name).to eq('sac_magazine')
          expect(positions[4].amount).to eq(25.0)
          expect(positions[5].name).to eq('service_fee')
          expect(positions[5].amount).to eq(1.0)
          expect(positions[6].name).to eq('section_fee')
          expect(positions[6].amount).to eq(88.0)
        end
      end
    end

    context 'child' do
      let(:model) { people(:familienmitglied_kind) }

      it 'generates positions' do
        expect(positions.size).to eq(5)

        expect(positions[0].name).to eq('section_fee')
        expect(positions[0].amount).to eq(0.0)
        expect(positions[1].name).to eq('sac_fee')
        expect(positions[1].amount).to eq(0.0)
        expect(positions[2].name).to eq('hut_solidarity_fee')
        expect(positions[2].amount).to eq(0.0)
        expect(positions[3].name).to eq('sac_magazine')
        expect(positions[3].amount).to eq(0.0)
        expect(positions[4].name).to eq('section_fee')
        expect(positions[4].amount).to eq(0.0)
      end
    end

    context 'middle of the year' do
      let(:date) { Date.new(2023, 8, 15)}
      let(:model) { people(:familienmitglied) }

      it 'generates discounted positions' do
        expect(positions.size).to eq(8)

        expect(positions[0].name).to eq('section_fee')
        expect(positions[0].amount).to eq(42.0)
        expect(positions[1].name).to eq('section_bulletin_postage_abroad')
        expect(positions[1].amount).to eq(6.5)
        expect(positions[2].name).to eq('sac_fee')
        expect(positions[2].amount).to eq(25.0)
        expect(positions[3].name).to eq('hut_solidarity_fee')
        expect(positions[3].amount).to eq(10.0)
        expect(positions[4].name).to eq('sac_magazine')
        expect(positions[4].amount).to eq(12.5)
        expect(positions[5].name).to eq('sac_magazine_postage_abroad')
        expect(positions[5].amount).to eq(5.0)
        expect(positions[6].name).to eq('service_fee')
        expect(positions[6].amount).to eq(1.0)
        expect(positions[7].name).to eq('section_fee')
        expect(positions[7].amount).to eq(44.0)
      end
    end

    context 'end of the year' do
      let(:date) { Date.new(2023, 11, 15)}
      let(:model) { people(:familienmitglied) }

      it 'generates discounted positions' do
        expect(positions.size).to eq(8)

        expect(positions[0].name).to eq('section_fee')
        expect(positions[0].amount).to eq(0.0)
        expect(positions[1].name).to eq('section_bulletin_postage_abroad')
        expect(positions[1].amount).to eq(0.0)
        expect(positions[2].name).to eq('sac_fee')
        expect(positions[2].amount).to eq(0.0)
        expect(positions[3].name).to eq('hut_solidarity_fee')
        expect(positions[3].amount).to eq(0.0)
        expect(positions[4].name).to eq('sac_magazine')
        expect(positions[4].amount).to eq(0.0)
        expect(positions[5].name).to eq('sac_magazine_postage_abroad')
        expect(positions[5].amount).to eq(0.0)
        expect(positions[6].name).to eq('service_fee')
        expect(positions[6].amount).to eq(1.0)
        expect(positions[7].name).to eq('section_fee')
        expect(positions[7].amount).to eq(0.0)
      end
    end
  end

  context 'with huts' do
    before do
      kommission = Group::SektionsHuettenkommission.create!(parent: main_section, name: 'Hüttenkommission')
      Group::SektionsHuette.create!(parent: kommission, name: 'Blüemlisalphütte')
    end

    it 'generates positions' do
      expect(positions[2].name).to eq('hut_solidarity_fee')
      expect(positions[2].amount).to eq(10.0)
    end
  end

  context 'honorary member section' do
    before do
      Group::SektionsMitglieder::Ehrenmitglied.create!(
        person: model,
        group: groups(:bluemlisalp_mitglieder),
        created_at: '2022-08-01'
      )
    end

    it 'generates positions' do
      expect(positions.size).to eq(9)

      expect(positions[0].name).to eq('section_fee')
      expect(positions[0].group).to eq(nil)
      expect(positions[0].amount).to eq(0.0)
      expect(positions[0].debitor).to eq(person)
      expect(positions[0].creditor.to_s).to eq(main_section.to_s)
      expect(positions[0].article_number).to eq(config.section_fee_article_number)

      expect(positions[1].name).to eq('sac_fee')
      expect(positions[1].group).to eq(:sac_fee)
      expect(positions[1].amount).to eq(0.0)
      expect(positions[1].debitor).to eq(person)
      expect(positions[1].creditor.to_s).to eq(sac.to_s)
      expect(positions[1].article_number).to eq(config.sac_fee_article_number)

      expect(positions[2].name).to eq('hut_solidarity_fee')
      expect(positions[2].group).to eq(:sac_fee)
      expect(positions[2].amount).to eq(0.0)
      expect(positions[2].debitor).to eq(person)
      expect(positions[2].creditor.to_s).to eq(sac.to_s)
      expect(positions[2].article_number).to eq(config.hut_solidarity_fee_article_number)

      expect(positions[3].name).to eq('sac_magazine')
      expect(positions[3].group).to eq(:sac_fee)
      expect(positions[3].amount).to eq(0.0)
      expect(positions[3].debitor).to eq(person)
      expect(positions[3].creditor.to_s).to eq(sac.to_s)
      expect(positions[3].article_number).to eq(config.magazine_fee_article_number)

      expect(positions[4].name).to eq('service_fee')
      expect(positions[4].group).to eq(nil)
      expect(positions[4].amount).to eq(1.0)
      expect(positions[4].debitor.to_s).to eq(main_section.to_s)
      expect(positions[4].creditor.to_s).to eq(sac.to_s)
      expect(positions[4].article_number).to eq(config.service_fee_article_number)

      expect(positions[5].name).to eq('balancing_payment')
      expect(positions[5].group).to eq(nil)
      expect(positions[5].amount).to eq(40.0)
      expect(positions[5].debitor.to_s).to eq(main_section.to_s)
      expect(positions[5].creditor.to_s).to eq(sac.to_s)
      expect(positions[5].article_number).to eq(config.balancing_payment_article_number)

      expect(positions[6].name).to eq('balancing_payment')
      expect(positions[6].group).to eq(nil)
      expect(positions[6].amount).to eq(20.0)
      expect(positions[6].debitor.to_s).to eq(main_section.to_s)
      expect(positions[6].creditor.to_s).to eq(sac.to_s)
      expect(positions[6].article_number).to eq(config.balancing_payment_article_number)

      expect(positions[7].name).to eq('balancing_payment')
      expect(positions[7].group).to eq(nil)
      expect(positions[7].amount).to eq(25.0)
      expect(positions[7].debitor.to_s).to eq(main_section.to_s)
      expect(positions[7].creditor.to_s).to eq(sac.to_s)
      expect(positions[7].article_number).to eq(config.balancing_payment_article_number)

      expect(positions[8].name).to eq('section_fee')
      expect(positions[8].group).to eq(nil)
      expect(positions[8].amount).to eq(56.0)
      expect(positions[8].debitor).to eq(person)
      expect(positions[8].creditor.to_s).to eq(additional_section.to_s)
      expect(positions[8].article_number).to eq(config.section_fee_article_number)
    end
  end

  context 'benefited member section' do
    before do
      Group::SektionsMitglieder::Beguenstigt.create!(
        person: model,
        group: groups(:bluemlisalp_mitglieder),
        created_at: '2022-08-01'
        )
    end

    it 'generates positions' do
      context.fetch_section(main_section).config.sac_fee_exemption_for_benefited_members = false
      context.fetch_section(main_section).config.section_fee_exemption_for_benefited_members = true

      expect(positions.size).to eq(6)

      expect(positions[0].name).to eq('section_fee')
      expect(positions[0].group).to eq(nil)
      expect(positions[0].amount).to eq(0.0)
      expect(positions[0].debitor).to eq(person)
      expect(positions[0].creditor.to_s).to eq(main_section.to_s)
      expect(positions[0].article_number).to eq(config.section_fee_article_number)

      expect(positions[1].name).to eq('sac_fee')
      expect(positions[1].group).to eq(:sac_fee)
      expect(positions[1].amount).to eq(40.0)
      expect(positions[1].debitor).to eq(person)
      expect(positions[1].creditor.to_s).to eq(sac.to_s)
      expect(positions[1].article_number).to eq(config.sac_fee_article_number)

      expect(positions[2].name).to eq('hut_solidarity_fee')
      expect(positions[2].group).to eq(:sac_fee)
      expect(positions[2].amount).to eq(20.0)
      expect(positions[2].debitor).to eq(person)
      expect(positions[2].creditor.to_s).to eq(sac.to_s)
      expect(positions[2].article_number).to eq(config.hut_solidarity_fee_article_number)

      expect(positions[3].name).to eq('sac_magazine')
      expect(positions[3].group).to eq(:sac_fee)
      expect(positions[3].amount).to eq(25.0)
      expect(positions[3].debitor).to eq(person)
      expect(positions[3].creditor.to_s).to eq(sac.to_s)
      expect(positions[3].article_number).to eq(config.magazine_fee_article_number)

      expect(positions[4].name).to eq('service_fee')
      expect(positions[4].group).to eq(nil)
      expect(positions[4].amount).to eq(1.0)
      expect(positions[4].debitor.to_s).to eq(main_section.to_s)
      expect(positions[4].creditor.to_s).to eq(sac.to_s)
      expect(positions[4].article_number).to eq(config.service_fee_article_number)

      expect(positions[5].name).to eq('section_fee')
      expect(positions[5].group).to eq(nil)
      expect(positions[5].amount).to eq(56.0)
      expect(positions[5].debitor).to eq(person)
      expect(positions[5].creditor.to_s).to eq(additional_section.to_s)
      expect(positions[5].article_number).to eq(config.section_fee_article_number)
    end

    it 'generates positions with sac exemption' do
      context.fetch_section(main_section).config.sac_fee_exemption_for_benefited_members = true
      context.fetch_section(main_section).config.section_fee_exemption_for_benefited_members = false

      expect(positions.size).to eq(9)

      expect(positions[0].name).to eq('section_fee')
      expect(positions[0].group).to eq(nil)
      expect(positions[0].amount).to eq(42.0)
      expect(positions[0].debitor).to eq(person)
      expect(positions[0].creditor.to_s).to eq(main_section.to_s)
      expect(positions[0].article_number).to eq(config.section_fee_article_number)

      expect(positions[1].name).to eq('sac_fee')
      expect(positions[1].group).to eq(:sac_fee)
      expect(positions[1].amount).to eq(0.0)
      expect(positions[1].debitor).to eq(person)
      expect(positions[1].creditor.to_s).to eq(sac.to_s)
      expect(positions[1].article_number).to eq(config.sac_fee_article_number)

      expect(positions[2].name).to eq('hut_solidarity_fee')
      expect(positions[2].group).to eq(:sac_fee)
      expect(positions[2].amount).to eq(0.0)
      expect(positions[2].debitor).to eq(person)
      expect(positions[2].creditor.to_s).to eq(sac.to_s)
      expect(positions[2].article_number).to eq(config.hut_solidarity_fee_article_number)

      expect(positions[3].name).to eq('sac_magazine')
      expect(positions[3].group).to eq(:sac_fee)
      expect(positions[3].amount).to eq(0.0)
      expect(positions[3].debitor).to eq(person)
      expect(positions[3].creditor.to_s).to eq(sac.to_s)
      expect(positions[3].article_number).to eq(config.magazine_fee_article_number)

      expect(positions[4].name).to eq('service_fee')
      expect(positions[4].group).to eq(nil)
      expect(positions[4].amount).to eq(1.0)
      expect(positions[4].debitor.to_s).to eq(main_section.to_s)
      expect(positions[4].creditor.to_s).to eq(sac.to_s)
      expect(positions[4].article_number).to eq(config.service_fee_article_number)

      expect(positions[5].name).to eq('balancing_payment')
      expect(positions[5].group).to eq(nil)
      expect(positions[5].amount).to eq(40.0)
      expect(positions[5].debitor.to_s).to eq(main_section.to_s)
      expect(positions[5].creditor.to_s).to eq(sac.to_s)
      expect(positions[5].article_number).to eq(config.balancing_payment_article_number)

      expect(positions[6].name).to eq('balancing_payment')
      expect(positions[6].group).to eq(nil)
      expect(positions[6].amount).to eq(20.0)
      expect(positions[6].debitor.to_s).to eq(main_section.to_s)
      expect(positions[6].creditor.to_s).to eq(sac.to_s)
      expect(positions[6].article_number).to eq(config.balancing_payment_article_number)

      expect(positions[7].name).to eq('balancing_payment')
      expect(positions[7].group).to eq(nil)
      expect(positions[7].amount).to eq(25.0)
      expect(positions[7].debitor.to_s).to eq(main_section.to_s)
      expect(positions[7].creditor.to_s).to eq(sac.to_s)
      expect(positions[7].article_number).to eq(config.balancing_payment_article_number)

      expect(positions[8].name).to eq('section_fee')
      expect(positions[8].group).to eq(nil)
      expect(positions[8].amount).to eq(56.0)
      expect(positions[8].debitor).to eq(person)
      expect(positions[8].creditor.to_s).to eq(additional_section.to_s)
      expect(positions[8].article_number).to eq(config.section_fee_article_number)
    end
  end

  context 'with sac reduction' do
    before do
      roles(:mitglied).update!(created_at: 52.years.ago)
    end

    it 'generates positions' do
      expect(positions.size).to eq(6)

      expect(positions[0].name).to eq('section_fee')
      expect(positions[0].amount).to eq(42.0)
      expect(positions[1].name).to eq('sac_fee')
      expect(positions[1].amount).to eq(30.0)
      expect(positions[2].name).to eq('hut_solidarity_fee')
      expect(positions[2].amount).to eq(20.0)
      expect(positions[3].name).to eq('sac_magazine')
      expect(positions[3].amount).to eq(25.0)
      expect(positions[4].name).to eq('service_fee')
      expect(positions[4].amount).to eq(1.0)
      expect(positions[5].name).to eq('section_fee')
      expect(positions[5].amount).to eq(41.0)
    end
  end

  context 'with section membership years reduction' do
    before do
      roles(:mitglied).update!(created_at: '1970-06-15')
      model.update(birthday: '1955-03-23')
      context.fetch_section(main_section).reduction_required_age = 0
    end

    it 'generates positions' do
      expect(positions.size).to eq(6)

      expect(positions[0].name).to eq('section_fee')
      expect(positions[0].amount).to eq(32.0)
      expect(positions[1].name).to eq('sac_fee')
      expect(positions[1].amount).to eq(30.0)
      expect(positions[2].name).to eq('hut_solidarity_fee')
      expect(positions[2].amount).to eq(20.0)
      expect(positions[3].name).to eq('sac_magazine')
      expect(positions[3].amount).to eq(25.0)
      expect(positions[4].name).to eq('service_fee')
      expect(positions[4].amount).to eq(1.0)
      expect(positions[5].name).to eq('section_fee')
      expect(positions[5].amount).to eq(41.0)
    end

    context 'middle of the year' do
      let(:date) { Date.new(2023, 7, 1)}

      it 'generates discounted positions' do
        expect(positions.size).to eq(6)

        expect(positions[0].name).to eq('section_fee')
        expect(positions[0].amount).to eq(16.0)
        expect(positions[1].name).to eq('sac_fee')
        expect(positions[1].amount).to eq(15.0)
        expect(positions[2].name).to eq('hut_solidarity_fee')
        expect(positions[2].amount).to eq(10.0)
        expect(positions[3].name).to eq('sac_magazine')
        expect(positions[3].amount).to eq(12.5)
        expect(positions[4].name).to eq('service_fee')
        expect(positions[4].amount).to eq(1.0)
        expect(positions[5].name).to eq('section_fee')
        expect(positions[5].amount).to eq(20.5)
      end
    end
  end

  context 'with section age reduction' do
    before do
      model.update(birthday: '1955-03-23')
      context.fetch_section(main_section).reduction_required_membership_years = nil
    end

    it 'generates positions' do
      expect(positions.size).to eq(6)

      expect(positions[0].name).to eq('section_fee')
      expect(positions[0].amount).to eq(32.0)
      expect(positions[1].name).to eq('sac_fee')
      expect(positions[1].amount).to eq(40.0)
      expect(positions[2].name).to eq('hut_solidarity_fee')
      expect(positions[2].amount).to eq(20.0)
      expect(positions[3].name).to eq('sac_magazine')
      expect(positions[3].amount).to eq(25.0)
      expect(positions[4].name).to eq('service_fee')
      expect(positions[4].amount).to eq(1.0)
      expect(positions[5].name).to eq('section_fee')
      expect(positions[5].amount).to eq(56.0)
    end
  end

  context 'new entry' do
    let(:positions) { described_class.new(person).new_entry_positions }

    context 'without neuanmeldung' do
      it 'generates no positions' do
        expect(positions).to eq([])
      end
    end

    context 'with neuanmeldung' do
      let(:model) { Fabricate(:person) }

      before do
        Group::SektionsNeuanmeldungenNv::Neuanmeldung.create!(
          person: model,
          group: groups(:bluemlisalp_neuanmeldungen_nv),
          created_at: date
        )
      end

      it 'generates positions' do
        expect(positions.size).to eq(7)

        expect(positions[0].name).to eq('section_fee')
        expect(positions[0].amount).to eq(42.0)
        expect(positions[1].name).to eq('sac_fee')
        expect(positions[1].amount).to eq(40.0)
        expect(positions[2].name).to eq('hut_solidarity_fee')
        expect(positions[2].amount).to eq(20.0)
        expect(positions[3].name).to eq('sac_magazine')
        expect(positions[3].amount).to eq(25.0)
        expect(positions[4].name).to eq('service_fee')
        expect(positions[4].amount).to eq(1.0)

        expect(positions[5].name).to eq('sac_entry_fee')
        expect(positions[5].amount).to eq(10.0)
        expect(positions[5].group).to eq(nil)
        expect(positions[5].debitor).to eq(person)
        expect(positions[5].creditor.to_s).to eq(sac.to_s)
        expect(positions[5].article_number).to eq(config.sac_entry_fee_article_number)

        expect(positions[6].name).to eq('section_entry_fee')
        expect(positions[6].amount).to eq(10.0)
        expect(positions[6].group).to eq(nil)
        expect(positions[6].debitor).to eq(person)
        expect(positions[6].creditor.to_s).to eq(main_section.to_s)
        expect(positions[6].article_number).to eq(config.section_entry_fee_article_number)
      end
    end

    context 'with ignored neuanmeldung sektion' do

      before do
        # this role is ignored
        Group::SektionsNeuanmeldungenSektion::Neuanmeldung.create!(
          person: model,
          group: groups(:bluemlisalp_neuanmeldungen_sektion),
          created_at: date
        )
      end

      it 'generates positions' do
        expect(positions.size).to eq(0)
      end

    end
  end

  context 'new section' do
    let(:positions) { described_class.new(person).new_additional_section_positions(main_section) }

    context 'without neuanmeldung' do
      it 'generates no positions' do
        expect(positions).to eq([])
      end
    end

    context 'with neuanmeldung' do
      let(:model) { Fabricate(:person) }

      before do
        Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.create!(
          person: model,
          group: groups(:bluemlisalp_neuanmeldungen_nv),
          created_at: date
        )
      end

      it 'generates positions' do
        expect(positions.size).to eq(2)

        expect(positions[0].name).to eq('section_fee')
        expect(positions[0].amount).to eq(42.0)
        expect(positions[1].name).to eq('service_fee')
        expect(positions[1].amount).to eq(1.0)
      end

      context 'living abroad' do
        before do
          model.update!(country: 'DE')
          context.fetch_section(additional_section).bulletin_postage_abroad = 0
        end


        it 'generates positions' do
          expect(positions.size).to eq(3)

          expect(positions[0].name).to eq('section_fee')
          expect(positions[0].amount).to eq(42.0)
          expect(positions[1].name).to eq('section_bulletin_postage_abroad')
          expect(positions[1].amount).to eq(13.0)
          expect(positions[2].name).to eq('service_fee')
          expect(positions[2].amount).to eq(1.0)
        end
      end
    end

    context 'with ignored neuanmeldung sektion' do

      before do
        # this role is ignored
        Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion.create!(
          person: model,
          group: groups(:bluemlisalp_neuanmeldungen_sektion),
          created_at: date
        )
      end

      it 'generates positions' do
        expect(positions.size).to eq(0)
      end

    end

  end

end
