# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'
require_relative '../../../../app/domain/sac_cas/beitragskategorie/calculator'

describe SacCas::Beitragskategorie::Calculator do

  def category(age: nil, household: false)
    described_class.new(person(age, household)).calculate
  end

  def person(age, household)
    birthday = Time.zone.today - age.years if age
    household_key = 'household' if household
    Fabricate.build(:person, birthday: birthday, household_key: household_key)
  end

  context '#calculate' do
    it 'returns einzel for person with 22 years or older' do
      expect(category(age: 22)).to eq(:einzel)
      expect(category(age: 99)).to eq(:einzel)
    end

    it 'returns jugend for person between 6 and 21 years not in a family' do
      expect(category(age: 6)).to eq(:jugend)
      expect(category(age: 15)).to eq(:jugend)
      expect(category(age: 21)).to eq(:jugend)
    end

    it 'returns familie for adult family member' do
      expect(category(age: 22, household: true)).to eq(:familie)
      expect(category(age: 99, household: true)).to eq(:familie)
    end

    it 'returns jugend for person between 17 and 21 if in same household with others' do
      expect(category(age: 17, household: true)).to eq(:jugend)
      expect(category(age: 21, household: true)).to eq(:jugend)
    end

    it 'returns nil for person younger than 6 years' do
      expect(category(age: 5)).to eq(nil)
    end

    it 'returns nil for person without birthday' do
      expect(category(age: nil)).to eq(nil)
    end
  end
end
