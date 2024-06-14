# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Memberships::MemberJoinSectionBase do
  def create_role(key, role, owner: person, **attrs)
    group = key.is_a?(Group) ? key : groups(key)
    role_type = group.class.const_get(role)
    Fabricate(role_type.sti_name, group: group, person: owner, **attrs)
  end

  it 'initialization fails on invalid group' do
    expect do
      described_class.new(Group::Sektion.new, :person, :date)
    end.not_to raise_error

    expect do
      described_class.new(Group::Ortsgruppe.new, :person, :date)
    end.not_to raise_error

    expect do
      described_class.new(Group::SacCas.new, :person, :date)
    end.to raise_error('group is not supported')
  end

  describe 'validations' do
    let(:person) { Fabricate(:person) }
    let(:group) { groups(:bluemlisalp) }
    let(:errors) { obj.errors.full_messages }
    let(:date) { Date.new(2024, 6, 14) }

    subject(:obj) { described_class.new(group, person, date) }

    it 'is invalid if person is not an sac member' do
      expect(obj).not_to be_valid
      expect(errors).to eq ['Person muss Sac Mitglied sein']
    end

    it 'is valid with membership in different section' do
      create_role(:matterhorn_mitglieder, 'Mitglied')
      expect(obj).to be_valid
    end

    describe 'existing membership in tree' do
      describe 'section' do
        it 'is invalid if person is section member' do
          create_role(:bluemlisalp_mitglieder, 'Mitglied')
          expect(obj).not_to be_valid
          expect(errors).to eq [
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch'
          ]
        end

        it 'is invalid if person has requested membership via section' do
          create_role(:bluemlisalp_neuanmeldungen_sektion, 'Neuanmeldung')
          expect(obj).not_to be_valid
          expect(errors).to eq [
            'Person muss Sac Mitglied sein',
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch'
          ]
        end

        it 'is invalid if person has requested membership via nv' do
          create_role(:bluemlisalp_neuanmeldungen_nv, 'Neuanmeldung')
          expect(obj).not_to be_valid
          expect(errors).to eq [
            'Person muss Sac Mitglied sein',
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch'
          ]
        end
      end

      describe 'ortsgruppe' do
        it 'is invalid if person is ortsgruppen member' do
          create_role(:bluemlisalp_ortsgruppe_ausserberg_mitglieder, 'Mitglied')
          expect(obj).not_to be_valid
          expect(errors).to eq [
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch'
          ]
        end

        it 'is invalid if person has requested membership' do
          create_role(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv, 'Neuanmeldung')
          expect(obj).not_to be_valid
          expect(errors).to eq [
            'Person muss Sac Mitglied sein',
            'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch'
          ]
        end
      end
    end

    context 'family main person' do
      it 'is invalid when obj validates and person is not main family person' do
        expect(obj).to receive(:validate_family_main_person?).and_return(true)
        create_role(:bluemlisalp_mitglieder, 'Mitglied')
        expect(obj).not_to be_valid
        expect(errors).to eq [
          'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch',
          'Person muss Hauptperson der Familie sein'
        ]
      end

      it 'is valid when obj validates and person is not main family person' do
        expect(obj).to receive(:validate_family_main_person?).and_return(true)
        person.update!(sac_family_main_person: true)
        role = create_role(:bluemlisalp_mitglieder, 'Mitglied').tap do |r|
          Role.where(id: r.id).update_all(beitragskategorie: :family)
        end
        expect(obj).not_to be_valid
        expect(errors).to eq [
          'Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch'
        ]
      end
    end
  end

  describe 'saving' do
    let(:person) { Fabricate(:person) }
    let(:group) { groups(:matterhorn) }
    let(:errors) { obj.errors.full_messages }
    let(:date) { Date.new(2024, 6, 14) }

    subject(:obj) { described_class.new(group, person, date) }

    context 'invalid' do
      it 'save returns false and populates errors' do
        expect(obj.save).to eq false
        expect(obj.errors.full_messages).to eq ['Person muss Sac Mitglied sein']
      end

      it 'save! raises' do
        expect { obj.save! }.to raise_error 'cannot save invalid model'
      end
    end

    context 'single person' do
      let(:funktionaere) { groups(:matterhorn_funktionaere) }
      before { create_role(:bluemlisalp_mitglieder, 'Mitglied') }

      it 'creates single role for person' do
        allow(obj).to receive(:build_roles) do |person|
          Fabricate.build(Group::SektionsFunktionaere::Praesidium.sti_name, person: person,
                                                                            group: funktionaere)
        end
        expect do
          expect(obj.save).to eq true
        end.to change { person.reload.roles.count }.by(1)
      end

      it 'might create multiple roles roles for single person' do
        allow(obj).to receive(:build_roles) do |person|
          [Fabricate.build(Group::SektionsFunktionaere::Praesidium.sti_name, person: person,
                                                                             group: funktionaere),
           Fabricate.build(Group::SektionsFunktionaere::Administration.sti_name, person: person,
                                                                                 group: funktionaere)]
        end
        expect do
          expect(obj.save).to eq true
        end.to change { person.reload.roles.count }.by(2)
      end
    end

    context 'family' do
      let(:other) { Fabricate(:person) }
      let(:funktionaere) { groups(:matterhorn_funktionaere) }

      def create_household(person, *others)
        others.each { |p| person.household.add(p) }
        person.household.save!
        person.reload
      end

      before do
        create_household(person, other)
        person.update!(sac_family_main_person: true)
        create_role(:bluemlisalp_mitglieder, 'Mitglied', beitragskategorie: :family)
        create_role(:bluemlisalp_mitglieder, 'Mitglied', owner: other.reload,
                                                         beitragskategorie: :family)
      end

      it 'creates roles for each member' do
        allow(obj).to receive(:build_roles) do |person|
          Fabricate.build(Group::SektionsFunktionaere::Praesidium.sti_name, person: person,
                                                                            group: funktionaere)
        end

        expect do
          expect(obj.save!).to eq true
        end.to change { Role.count }.by(2)
      end
    end

  end
end
