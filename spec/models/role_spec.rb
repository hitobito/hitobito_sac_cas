# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Role do

  let(:person) { Fabricate(:person) }
  let(:bluemlisalp_mitglieder) { groups(:bluemlisalp_mitglieder) }
  let(:bluemlisalp_neuanmeldungen_nv) { groups(:bluemlisalp_neuanmeldungen_nv) }
  let(:bluemlisalp_neuanmeldungen_sektion) { groups(:bluemlisalp_neuanmeldungen_sektion) }

  context 'Mitglied vs. Beitragskategorie' do
    it 'assigns correct beitragskategorie when creating new mitglied role' do
      person.update!(birthday: Time.zone.today - 33.years)

      role = Group::SektionsMitglieder::Mitglied.create!(person: person, group: bluemlisalp_mitglieder)

      expect(role.beitragskategorie).to eq('einzel')
    end

    it 'is not valid without beitragskategorie or person\'s birthdate' do
      role = Group::SektionsMitglieder::Mitglied.new(person: person, group: bluemlisalp_mitglieder)

      expect(role).not_to be_valid
    end

    it 'assigns correct beitragskategorie when creating new neuanmeldung role' do
      person.update!(birthday: Time.zone.today - 17.years)

      neuanmeldung_nv =
        Group::SektionsNeuanmeldungenNv::Neuanmeldung.create!(
          person: person, group: bluemlisalp_neuanmeldungen_nv)

      expect(neuanmeldung_nv.beitragskategorie).to eq('jugend')

      neuanmeldung_sektion = Group::SektionsNeuanmeldungenSektion::Neuanmeldung.create!(
        person: person, group: bluemlisalp_neuanmeldungen_sektion)

      expect(neuanmeldung_sektion.beitragskategorie).to eq('jugend')
    end

    it 'is not valid without beitragskategorie or person\'s birthdate' do
      neuanmeldung_nv =
        Group::SektionsNeuanmeldungenNv::Neuanmeldung.new(
          person: person, group: bluemlisalp_neuanmeldungen_nv)

      expect(neuanmeldung_nv).not_to be_valid

      neuanmeldung_sektion =
        Group::SektionsNeuanmeldungenSektion::Neuanmeldung.new(
          person: person, group: bluemlisalp_neuanmeldungen_sektion)

      expect(neuanmeldung_sektion).not_to be_valid
    end
  end


  describe 'minimum age validation' do
    [
      [Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder],
      [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion],
      [Group::SektionsNeuanmeldungenNv::Neuanmeldung, :bluemlisalp_neuanmeldungen_nv],
    ].each do |role_type, group|
      it "does not accept person without birthday for #{role_type}" do
        person.birthday = nil
        role = person.roles.build(type: role_type, group: groups(group))
        expect(role).not_to be_valid
        expect(role.errors[:person]).to include('muss ein Geburtsdatum haben und mindestens 6 Jahre alt sein')
      end

      it "accepts person exceeding age restriction for #{role_type}" do
        person.birthday = 6.years.ago - 1.day
        role = person.roles.build(type: role_type, group: groups(group), beitragskategorie: :einzel)
        expect(role).to be_valid
      end

      it "rejects person below age restriction for #{role_type}" do
        person.birthday = 5.years.ago
        role = person.roles.build(type: role_type, group: groups(group), beitragskategorie: :einzel)
        expect(role).not_to be_valid
        expect(role.errors[:person]).to include('muss ein Geburtsdatum haben und mindestens 6 Jahre alt sein')
      end
    end

    it 'accepts person below age limit on other group' do
        person.birthday = 5.years.ago
        role = person.roles.build(type: Group::Geschaeftsstelle::ITSupport, group: groups(:geschaeftsstelle))
        expect(role).to be_valid
    end
  end
end
