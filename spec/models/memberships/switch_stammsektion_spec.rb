# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Memberships::SwitchStammsektion do
  def create_role(key, role, owner: person, **attrs)
    group = key.is_a?(Group) ? key : groups(key)
    role_type = group.class.const_get(role)
    Fabricate(role_type.sti_name, group: group, person: owner, **attrs)
  end

  it 'initialization fails on invalid group' do
    expect do
      described_class.new(Group::Sektion.new, :person, :join_date)
    end.not_to raise_error

    expect do
      described_class.new(Group::Ortsgruppe.new, :person, :join_date)
    end.not_to raise_error

    expect do
      described_class.new(Group::SacCas.new, :person, :join_date)
    end.to raise_error('must be section/ortsgruppe')
  end

  let(:now) { Time.zone.local(2024, 6, 19, 15, 33) }
  subject(:switch) { described_class.new(join_section, person, now.to_date) }
  before { travel_to(now) }

  describe 'validations' do
    let(:person) { Fabricate(:person) }
    let(:join_section) { groups(:bluemlisalp) }
    let(:errors) { switch.errors.full_messages }

    it 'is invalid if person is not an sac member' do
      expect(switch).not_to be_valid
      expect(errors).to eq ['Person muss Sac Mitglied sein']
    end

    it 'is valid with membership in different section' do
      create_role(:matterhorn_mitglieder, 'Mitglied')
      expect(switch).to be_valid
    end

    describe 'join_date' do
      def switch_on(join_date) = described_class.new(join_section, person, join_date)

      it 'is valid on today and first day of next year' do
        create_role(:matterhorn_mitglieder, 'Mitglied')
        expect(switch_on(now.to_date)).to be_valid
        expect(switch_on(now.next_year.beginning_of_year.to_date)).to be_valid
        expect(switch_on(now)).not_to be_valid
        expect(switch_on(now.next_year.beginning_of_year)).not_to be_valid
        expect(switch_on(now.next_year.beginning_of_year.to_date + 1.day)).not_to be_valid
      end
    end

    describe 'existing membership in tree' do
      describe 'join section' do
        it 'is invalid if person is join_section member' do
          create_role(:bluemlisalp_mitglieder, 'Mitglied')
          expect(switch).not_to be_valid
          expect(errors).to eq [
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch',
            "#{person}: Person ist bereits Mitglied (von 19.06.2024 bis 31.12.2024)."
          ]
        end

        it 'is invalid if person has requested membership in join section with approval' do
          create_role(:bluemlisalp_neuanmeldungen_sektion, 'Neuanmeldung')
          expect(switch).not_to be_valid
          expect(errors).to eq [
            'Person muss Sac Mitglied sein',
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch',
            "#{person}: Person hat bereits eine Neuanmeldung (von 19.06.2024 bis 31.12.2024)."
          ]
        end

        it 'is invalid if person has requested membership in join section' do
          create_role(:bluemlisalp_neuanmeldungen_nv, 'Neuanmeldung')
          expect(switch).not_to be_valid
          expect(errors).to eq [
            'Person muss Sac Mitglied sein',
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch',
            "#{person}: Person hat bereits eine Neuanmeldung (von 19.06.2024 bis 31.12.2024)."
          ]
        end
      end

      describe 'ortsgruppe' do
        it 'is invalid if person is ortsgruppen member' do
          create_role(:bluemlisalp_ortsgruppe_ausserberg_mitglieder, 'Mitglied')
          expect(switch).not_to be_valid
          expect(errors).to eq [
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch',
            "#{person}: Person ist bereits Mitglied (von 19.06.2024 bis 31.12.2024)."
          ]
        end

        it 'is invalid if person has requested membership' do
          create_role(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv, 'Neuanmeldung')
          expect(switch).not_to be_valid
          expect(errors).to eq [
            'Person muss Sac Mitglied sein',
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch',
            "#{person}: Person hat bereits eine Neuanmeldung (von 19.06.2024 bis 31.12.2024)."
          ]
        end
      end
    end
  end

  describe 'saving' do
    let(:person) { Fabricate(:person) }
    let(:group) { groups(:matterhorn) }
    let(:errors) { switch.errors.full_messages }

    subject(:switch) { described_class.new(group, person, now.to_date) }

    context 'invalid' do
      it 'save returns false and populates errors' do
        expect(switch.save).to eq false
        expect(switch.errors.full_messages).to eq ['Person muss Sac Mitglied sein']
      end

      it 'save! raises' do
        expect { switch.save! }.to raise_error 'cannot save invalid model'
      end
    end

    context 'single person' do
      let(:matterhorn_mitglieder) { groups(:matterhorn_mitglieder) }
      let(:matterhorn_funktionaere) { groups(:matterhorn_funktionaere) }
      let!(:bluemlisalp_mitglied) { create_role(:bluemlisalp_mitglieder, 'Mitglied') }
      let(:matterhorn_mitglied) { matterhorn_mitglieder.roles.find_by(person: person) }

      it 'creates new role and terminates existing' do
        expect do
          expect(switch.save).to eq true
        end.not_to(change { person.reload.roles.count })
        expect(bluemlisalp_mitglied.reload.deleted_at).to eq now.yesterday.end_of_day.to_s(:db)
        expect(matterhorn_mitglied.created_at).to eq now.to_s(:db)
        expect(matterhorn_mitglied.delete_on).to eq now.end_of_year.to_date
      end

      context 'switching next year' do
        subject(:switch) { described_class.new(group, person, now.next_year.beginning_of_year.to_date) }
        
        it 'creates new role and terminates existing' do
          expect do
            expect(switch.save).to eq true
          end.to change { person.reload.roles.count }.by(1)
          expect(bluemlisalp_mitglied.reload.deleted_at).to be_nil
          expect(bluemlisalp_mitglied.delete_on).to eq now.end_of_year.to_date
          expect(matterhorn_mitglied.type).to eq 'FutureRole'
          expect(matterhorn_mitglied.convert_on).to eq now.next_year.beginning_of_year.to_date
        end

        it 'does not prolong already terminated membership role' do
          bluemlisalp_mitglied.update!(delete_on: 3.days.from_now)
          expect do
            expect(switch.save).to eq true
          end.to change { person.reload.roles.count }.by(1)
          expect(bluemlisalp_mitglied.reload.deleted_at).to be_nil
          expect(bluemlisalp_mitglied.delete_on).to eq 3.days.from_now.to_date
        end
      end
    end

    context 'family' do
      let(:other) { Fabricate(:person) }
      let(:matterhorn_mitglieder) { groups(:matterhorn_mitglieder) }
      let(:matterhorn_mitglied) { matterhorn_mitglieder.roles.find_by(person: person) }
      let(:matterhorn_mitglied_other) { matterhorn_mitglieder.roles.find_by(person: other) }

      def create_sac_family(person, *others)
        others.each { |p| person.household.add(p) }
        person.household.save!
        person.reload
      end

      before do
        create_sac_family(person, other)
        person.update!(sac_family_main_person: true)
        @bluemlisalp_mitglied = create_role(:bluemlisalp_mitglieder, 'Mitglied', beitragskategorie: :family)
        @bluemlisalp_mitglied_other = create_role(
          :bluemlisalp_mitglieder,
          'Mitglied',
          beitragskategorie: :family,
          owner: other.reload
        )
      end

      it 'is invalid if switch is attempted with person that is not a sac_family_main_person' do
        switch = described_class.new(group, other, now)
        expect(switch).not_to be_valid
        expect(switch.errors.full_messages).to include('Person muss Hauptperson der Familie sein')
      end

      it 'creates new and terminates existing roles for each member' do
        expect do
          expect(switch.save!).to eq true
        end.not_to change { Role.count }
        expect(@bluemlisalp_mitglied.reload.deleted_at).to eq now.yesterday.end_of_day.to_s(:db)
        expect(@bluemlisalp_mitglied_other.reload.deleted_at).to eq now.yesterday.end_of_day.to_s(:db)
        expect(matterhorn_mitglied.created_at).to eq now.to_s(:db)
        expect(matterhorn_mitglied.delete_on).to eq now.end_of_year.to_date
        expect(matterhorn_mitglied_other.created_at).to eq now.to_s(:db)
        expect(matterhorn_mitglied_other.delete_on).to eq now.end_of_year.to_date
      end

      context 'switching next year' do
        subject(:switch) { described_class.new(group, person, now.next_year.beginning_of_year.to_date) }
        
        it 'creates new role and terminates existing' do
          expect do
            expect(switch.save).to eq true
          end.to change { person.reload.roles.count }.by(1)
          expect(@bluemlisalp_mitglied.reload.deleted_at).to be_nil
          expect(@bluemlisalp_mitglied.delete_on).to eq now.end_of_year.to_date
          expect(@bluemlisalp_mitglied_other.reload.deleted_at).to be_nil
          expect(@bluemlisalp_mitglied_other.delete_on).to eq now.end_of_year.to_date
          expect(matterhorn_mitglied.type).to eq 'FutureRole'
          expect(matterhorn_mitglied.convert_on).to eq now.next_year.beginning_of_year.to_date
          expect(matterhorn_mitglied_other.type).to eq 'FutureRole'
          expect(matterhorn_mitglied_other.convert_on).to eq now.next_year.beginning_of_year.to_date
        end

        it 'does not prolong already terminated membership role' do
          @bluemlisalp_mitglied.update!(delete_on: 3.days.from_now)
          @bluemlisalp_mitglied_other.update!(delete_on: 3.weeks.from_now)
          expect do
            expect(switch.save).to eq true
          end.to change { person.reload.roles.count }.by(1)
          expect(@bluemlisalp_mitglied.reload.deleted_at).to be_nil
          expect(@bluemlisalp_mitglied.delete_on).to eq 3.days.from_now.to_date
          expect(@bluemlisalp_mitglied_other.reload.deleted_at).to be_nil
          expect(@bluemlisalp_mitglied_other.delete_on).to eq 3.weeks.from_now.to_date
        end
      end
    end
  end
end