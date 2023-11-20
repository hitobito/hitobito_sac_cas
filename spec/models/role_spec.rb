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

  describe 'family members validation' do
    [
      [Group::SektionsMitglieder::Mitglied, :bluemlisalp_mitglieder],
      [Group::SektionsNeuanmeldungenSektion::Neuanmeldung, :bluemlisalp_neuanmeldungen_sektion],
      [Group::SektionsNeuanmeldungenNv::Neuanmeldung, :bluemlisalp_neuanmeldungen_nv]
    ].each do |role_type, group|
      context "for #{role_type}" do
        let(:role_type) { role_type }
        let(:group) { group }

        def build_role(age: 22, beitragskategorie: :familie, household_key: 'household42')
          person = Fabricate.build(:person, birthday: age.years.ago,
                                            household_key: household_key)
          role = role_type.new(person: person, group: groups(group),
                        beitragskategorie: beitragskategorie)
          person.primary_group = role.group
          role
        end

        it 'beitragskategorie=familie is accepted on primary group' do
          role = build_role
          role.person.primary_group = role.group

          expect(role).to be_valid
        end

        it 'beitragskategorie=familie is rejected on non-primary group' do
          role = build_role
          role.person.primary_group = groups(:geschaeftsstelle)

          expect(role).not_to be_valid
          expect(role.errors[:base]).to include('Familienmitgliedschaften sind nur auf der Hauptsektion möglich.')
        end

        context 'adult family members count' do
          context 'with beitragskategorie=familie' do
            it 'accepts single adult person in household' do
              expect(build_role).to be_valid
            end

            it 'accepts second adult person in same household' do
              # Add 1 adult
              build_role.save!

              # Test second adult
              expect(build_role).to be_valid
            end

            it 'rejects third adult person in same household' do
              # Add 2 adults
              2.times { build_role.save! }

              # Test third adult
              third_adult = build_role
              expect(third_adult).not_to be_valid
              expect(third_adult.errors[:base]).to include('In einer Familienmitgliedschaft sind maximal 2 Erwachsene inbegriffen.')
            end

            it 'accepts third youth person in same household' do
              # Add 2 adults and 2 youth
              2.times { build_role.save! }
              2.times { build_role(age: 17, beitragskategorie: :jugend).save! }

              # Test third youth
              third_youth = build_role(age: 17)
              expect(third_youth).to be_valid
            end

            it 'accepts third adult in different household' do
              # Add 2 adults
              2.times { build_role(household_key: '1stHousehold').save! }

              # Test third adult in different household
              third_adult = build_role(household_key: '2ndHousehold')
              expect(third_adult).to be_valid
            end
          end

          context 'with beitragskategorie=einzel' do
          it 'accepts third adult in same household' do
            # Add 2 adults with beitragskategorie=familie
            2.times { build_role(beitragskategorie: :familie).save! }

            # Test third adult with beitragskategorie=einzel
            # This is a special case, because the person is part of the same household, but
            # is not included in the family membership.
            third_adult = build_role(beitragskategorie: :einzel)
            expect(third_adult).to be_valid
          end
          end
        end
      end
    end
  end

  describe 'primary_group' do
    let(:funktionaere) { groups(:bluemlisalp_funktionaere) }
    let(:primary) { groups(:geschaeftsstelle) }
    let(:mitglieder) {  groups(:bluemlisalp_mitglieder) }

    context 'with primary_group not a preferred_primary' do
      let(:person) { people(:admin) }

      it "does not change when creating normal role" do
        expect do
          Fabricate(Group::SektionsFunktionaere::Praesidium.sti_name, group: funktionaere, person: person)
        end.not_to change { person.reload.primary_group }
      end

      it "does change when creating preferred role" do
        expect do
          Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: mitglieder, person: person, beitragskategorie: :einzel)
        end.to change { person.reload.primary_group }.from(primary).to(mitglieder)
      end

      it "does change back when destroying preferred role" do
        role = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: mitglieder, person: person, beitragskategorie: :einzel)
        expect do
          role.destroy
        end.to change { person.reload.primary_group }.from(mitglieder).to(primary)
      end
    end

    context 'with primary_group a preferred_primary' do
      let(:person) { people(:mitglied) }

      it "does not change when creating normal role" do
        expect do
          Fabricate(Group::SektionsFunktionaere::Praesidium.sti_name, group: funktionaere, person: person)
        end.not_to change { person.reload.primary_group }
      end

      it "does not change when creating preferred role" do
        other = Fabricate(Group::Sektion.sti_name, parent: groups(:root), foundation_year: 2023).children
          .find_by(type: Group::SektionsMitglieder)
        expect do
          Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: other, person: person, beitragskategorie: :einzel)
        end.not_to change { person.reload.primary_group }
      end

      it "does change back when destroying preferred role" do
        Fabricate(Group::SektionsFunktionaere::Praesidium.sti_name, group: funktionaere, person: person)
        expect do
          roles(:mitglied).destroy
        end.to change { person.reload.primary_group }.from(mitglieder).to(funktionaere)
      end
    end
  end

  describe '#to_s' do
    let(:person) { people(:mitglied) }

    it 'does not have zusatzsektion suffix on primary group role' do
      expect(roles(:mitglied).to_s).to eq 'Mitglied (Einzel)'
    end

    it 'includes zusatzsektion suffix' do
      other = Fabricate(Group::Sektion.sti_name, parent: groups(:root), foundation_year: 2023).children
        .find_by(type: Group::SektionsMitglieder)
      role = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: other, person: person, beitragskategorie: :einzel)
      expect(role.to_s).to eq 'Mitglied (Einzel) (Zusatzsektion)'
    end
  end
end
