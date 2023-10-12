# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'
require_relative '../../../../app/domain/sac_cas/beitragskategorie/calculator'

describe SacCas::Beitragskategorie::Calculator do

  let(:category) { described_class.new(person.reload).calculate }
  let(:person) do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
              group: groups(:be_mitglieder)
             ).person 
  end
  let(:other_person) do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
              group: groups(:be_mitglieder)
             ).person 
  end

  context '#calculate' do
    it 'returns einzel for person with 22 years or older' do
      person.update!(birthday: Time.zone.today - 42.years)

      expect(category).to eq(:einzel)
    end

    it 'returns jugend for person between 6 and 21 years not in a family' do
      person.update!(birthday: Time.zone.today - 11.years)

      expect(category).to eq(:jugend)
    end

    it 'returns familie for family member' do
      assign_household(person, other_person)

      expect(category).to eq(:familie)
    end

    it 'returns jugend for person between 17 and 21 if in same household with others' do
      assign_household(person, other_person)
      person.update!(birthday: Time.zone.today - 18.years)

      expect(category).to eq(:jugend)
    end

    it 'returns nil for person younger than 6 years' do
      person.update!(birthday: Time.zone.today - 5.years)

      expect(category).to eq(nil)
    end
  end

  private

  def assign_household(person, other)
    ability = double
    allow(ability).to receive(:update?).and_return(true)
    Person::Household.new(person, ability, other, Person.first).save
  end

end
