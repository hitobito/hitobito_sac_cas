# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe SacCas::People::SacFamily do
  let(:adult) { people(:familienmitglied) }
  let(:adult2) { people(:familienmitglied2) }
  let(:child) { people(:familienmitglied_kind) }

  let(:today) { Time.zone.today }
  let(:end_of_year) do
    if today == today.end_of_year
      (today + 1.days).end_of_year
    else
      today.end_of_year
    end
  end

  let!(:household_member_jugend) do
    person = Fabricate(:person, household_key: '4242', birthday: today - 19.years)
    Group::SektionsMitglieder::Mitglied.create!(
      group: groups(:bluemlisalp_mitglieder),
      person: person,
      beitragskategorie: :jugend,
      created_at: today.beginning_of_year,
      delete_on: end_of_year
    )
    person
  end

  let!(:household_member_einzel) do
    person = Fabricate(:person, household_key: '4242', birthday: today - 42.years)
    Group::SektionsMitglieder::Mitglied.create!(
      group: groups(:bluemlisalp_mitglieder),
      person: person,
      beitragskategorie: :einzel,
      created_at: today.beginning_of_year,
      delete_on: end_of_year
    )
    person
  end

  let!(:household_other_sektion_member) do
    person = Fabricate(:person, household_key: '4242', birthday: today - 88.years)
    Group::SektionsMitglieder::Mitglied.create!(
      group: groups(:matterhorn_mitglieder),
      person: person,
      beitragskategorie: :einzel,
      created_at: today.beginning_of_year,
      delete_on: end_of_year
    )
    person
  end

  let(:subject) { described_class.new(person) }

  context '#family_members' do
    it 'returns all family members' do
      family_members = adult.sac_family.family_members
      
      expect(family_members).to include adult
      expect(family_members).to include adult2
      expect(family_members).to include child

      expect(family_members).not_to include household_member_jugend
      expect(family_members).not_to include household_other_sektion_member
      expect(family_members).not_to include household_member_einzel

      expect(family_members.count).to eq(3)
    end

    it 'returns all family members linked by neuanmeldung roles' do
      Group::SektionsMitglieder::Mitglied.where(group: groups(:bluemlisalp_mitglieder))
        .update_all(group_id: groups(:bluemlisalp_neuanmeldungen_sektion).id,
                    created_at: 7.days.ago,
                    delete_on: today + 20.days,
                    type: Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name)

      expect(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.count).to eq(6)

      family_members = adult.sac_family.family_members
      
      expect(family_members).to include adult
      expect(family_members).to include adult2
      expect(family_members).to include child

      expect(family_members).not_to include household_member_jugend
      expect(family_members).not_to include household_other_sektion_member
      expect(family_members).not_to include household_member_einzel

      expect(family_members.count).to eq(3)
    end
  end

  context '#member?' do
    it 'is never a family member if not in a household' do
      expect(people(:mitglied).sac_family.member?).to eq(false)
    end

    it 'is not a family member if in same household but other sektion' do
      expect(household_other_sektion_member.sac_family.member?).to eq(false)
    end

    it 'is not a family member if in same household but jugend mitglied' do
      expect(household_member_jugend.sac_family.member?).to eq(false)
    end

    it 'is family member' do
      [adult, adult2, child].each do |p|
        expect(p.sac_family.member?).to eq(true)
      end
    end
  end

end
