# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Memberships::JoinZusatzsektion do
  def create_role(key, role, owner: person, **attrs)
    group = key.is_a?(Group) ? key : groups(key)
    role_type = group.class.const_get(role)
    Fabricate(role_type.sti_name, group: group, person: owner, **attrs)
  end

  it 'initialization fails if no neuanmeldungen subgroup exists' do
    expect do
      described_class.new(Group::Sektion.new, :person, :date)
    end.to raise_error('missing neuanmeldungen subgroup')

    expect do
      described_class.new(Group::Ortsgruppe.new, :person, :date)
    end.to raise_error('missing neuanmeldungen subgroup')

    expect do
      described_class.new(groups(:bluemlisalp), :person, :date)
    end.not_to raise_error

    expect do
      described_class.new(groups(:bluemlisalp_ortsgruppe_ausserberg), :person, :date)
    end.not_to raise_error
  end

  describe 'validations' do
    let(:person) { Fabricate(:person) }
    let(:join_section) { groups(:bluemlisalp) }
    let(:errors) { join_sektion.errors.full_messages }
    let(:date) { Date.new(2024, 6, 14) }

    subject(:join_sektion) { described_class.new(join_section, person, date) }

    it 'is invalid if person is not an sac member' do
      expect(join_sektion).not_to be_valid
      expect(errors).to eq ['Person muss Sac Mitglied sein']
    end

    it 'is valid with membership in different section' do
      create_role(:matterhorn_mitglieder, 'Mitglied')
      expect(join_sektion).to be_valid
    end

    describe 'existing membership in tree' do
      describe 'join section' do
        it 'is invalid if person is already join section member' do
          create_role(:bluemlisalp_mitglieder, 'Mitglied')
          expect(join_sektion).not_to be_valid
          expect(errors).to eq [
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch'
          ]
        end

        it 'is invalid if person has requested membership in join section with approval' do
          create_role(:bluemlisalp_neuanmeldungen_sektion, 'Neuanmeldung')
          expect(join_sektion).not_to be_valid
          expect(errors).to eq [
            'Person muss Sac Mitglied sein',
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch'
          ]
        end

        it 'is invalid if person has requested membership in join section' do
          create_role(:bluemlisalp_neuanmeldungen_nv, 'Neuanmeldung')
          expect(join_sektion).not_to be_valid
          expect(errors).to eq [
            'Person muss Sac Mitglied sein',
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch'
          ]
        end
      end

      describe 'ortsgruppe' do
        it 'is valid if person is ortsgruppen member' do
          create_role(:bluemlisalp_ortsgruppe_ausserberg_mitglieder, 'Mitglied')
          expect(join_sektion).to be_valid
        end

        it 'is invalid if person has requested membership' do
          create_role(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv, 'Neuanmeldung')
          expect(join_sektion).not_to be_valid
          expect(errors).to eq [
            'Person muss Sac Mitglied sein'
          ]
        end
      end
    end

    context 'family main person' do
      it 'is invalid when join_sektion validates and person is not main family person' do
        expect(join_sektion).to receive(:validate_family_main_person?).and_return(true)
        create_role(:bluemlisalp_mitglieder, 'Mitglied')
        expect(join_sektion).not_to be_valid
        expect(errors).to eq [
          'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch',
          'Person muss Hauptperson der Familie sein'
        ]
      end

      it 'is valid when join_sektion validates and person is not main family person' do
        expect(join_sektion).to receive(:validate_family_main_person?).and_return(true)
        person.update!(sac_family_main_person: true)
        role = create_role(:bluemlisalp_mitglieder, 'Mitglied').tap do |r|
          Role.where(id: r.id).update_all(beitragskategorie: :family)
        end
        expect(join_sektion).not_to be_valid
        expect(errors).to eq [
          'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch'
        ]
      end
    end
  end

  describe 'saving' do
    let(:person) { Fabricate(:person) }
    let(:sektion) { groups(:matterhorn) }
    let(:errors) { join_sektion.errors.full_messages }
    let(:date) { Date.new(2024, 6, 14) }

    let(:role) { (person.roles - [mitglied]).first }
    subject(:join_sektion) { described_class.new(sektion, person, date) }

    context 'invalid' do
      it 'save returns false and populates errors' do
        expect(join_sektion.save).to eq false
        expect(join_sektion.errors.full_messages).to eq ['Person muss Sac Mitglied sein']
      end

      it 'save! raises' do
        expect { join_sektion.save! }.to raise_error(/cannot save invalid model/)
      end
    end

    context 'single person' do
      describe 'neuanmeldungen priority in sektion' do
        let!(:mitglied) { create_role(:bluemlisalp_mitglieder, 'Mitglied') }

        it 'prefers to create role in NeuanmeldungenSektion group' do
          expect { join_sektion.save! }.to change { person.reload.roles.count }.by(1)
          expect(role.group).to eq groups(:matterhorn_neuanmeldungen_sektion)
          expect(role.type).to eq 'Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion'
        end

        it 'falls back to create role in NeuanmeldungenSektionNv group' do
          groups(:matterhorn_neuanmeldungen_sektion).destroy
          expect { join_sektion.save! }.to change { person.reload.roles.count }.by(1)
          expect(role.group).to eq groups(:matterhorn_neuanmeldungen_nv)
          expect(role.type).to eq 'Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion'
        end
      end

      describe 'neuanmeldungen priority in ortsgruppe' do
        let!(:mitglied) { create_role(:matterhorn_mitglieder, 'Mitglied') }
        let(:sektion) { groups(:bluemlisalp_ortsgruppe_ausserberg) }

        it 'prefers to create role in NeuanmeldungenSektion group' do
          neuanmeldungen = Fabricate(Group::SektionsNeuanmeldungenSektion.sti_name,
                                     parent: sektion)
          expect { join_sektion.save! }.to change { person.reload.roles.count }.by(1)
          expect(role.group).to eq neuanmeldungen
          expect(role.type).to eq 'Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion'
        end

        it 'falls back to create role in NeuanmeldungenSektionNv group' do
          expect { join_sektion.save! }.to change { person.reload.roles.count }.by(1)
          expect(role.group).to eq groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv)
          expect(role.type).to eq 'Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion'
        end
      end
    end

    context 'family' do
      let(:other) { Fabricate(:person) }
      let(:matterhorn_mitglieder) { groups(:matterhorn_mitglieder) }

      def role(_owner = person)
        person.roles.find_by(type: 'Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion')
      end

      def create_sac_family(person, *others)
        others.each { |p| person.household.add(p) }
        person.household.save!
        person.reload
      end

      before do
        create_sac_family(person, other)
        person.update!(sac_family_main_person: true)
        create_role(:bluemlisalp_mitglieder, 'Mitglied', beitragskategorie: :family)
        create_role(:bluemlisalp_mitglieder, 'Mitglied', owner: other.reload,
                                                         beitragskategorie: :family)
      end

      context 'when sac_family_membership flag is not passed' do
        it 'creates role with adult category for single person' do
          expect do
            expect(join_sektion.save!).to eq true
          end.to change { Role.count }.by(1)
          expect(role.beitragskategorie).to eq 'adult'
        end
      end

      context 'without providing sac_family_membership flag is passed as true' do
        subject(:join_sektion) do
          described_class.new(sektion, person, date, sac_family_membership: true)
        end

        it 'creates roles with family category for both people' do
          expect do
            expect(join_sektion.save!).to eq true
          end.to change { Role.count }.by(2)
          expect(role.beitragskategorie).to eq 'family'
          expect(role(other).beitragskategorie).to eq 'family'
        end
      end
    end
  end
end
