# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Export::Tabular::People::SacRecipientRow do
  let(:group) { groups(:bluemlisalp_mitglieder) }

  let(:person) do
    Fabricate.build(
      :person,
      id: 42,
      first_name: 'Hans',
      last_name: 'Muster',
      street: 'Musterstrasse',
      housenumber: '42',
      zip_code: '4242',
      town: 'Musterhausen',
      country: 'Schweiz',
      email: 'hans.muster@example.com'
    )
  end

  subject(:row) { described_class.new(person, group) }

  def value(key) = row.fetch(key)

  it('id') { expect(value(:id)).to eq 42 }
  it('salutation') { expect(value(:salutation)).to be_nil }
  it('first_name') { expect(value(:first_name)).to eq 'Hans' }
  it('last_name') { expect(value(:last_name)).to eq 'Muster' }
  it('adresszusatz') { expect(value(:adresszusatz)).to be_nil }
  it('address') { expect(value(:address)).to eq 'Musterstrasse 42' }
  it('postfach') { expect(value(:postfach)).to be_nil }
  it('zip_code') { expect(value(:zip_code)).to eq '4242' }
  it('town') { expect(value(:town)).to eq 'Musterhausen' }
  it('email') { expect(value(:email)).to eq 'hans.muster@example.com' }
  it('layer_navision_id') do
    expect(value(:layer_navision_id)).to eq groups(:bluemlisalp).navision_id
  end

  describe '#country' do
    it 'returns country code for non-CH country' do
      person.country = 'DE'
      expect(value(:country)).to eq('Deutschland')
    end

    it 'returns nil for CH country' do
      person.country = 'CH'
      expect(value(:country)).to be_nil
    end
  end

end
