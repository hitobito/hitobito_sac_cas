# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Import::Sektion::Mitglied do
  let(:emails) { [] }
  let(:group) { Group::SektionsMitglieder.new(id: 1) }
  let(:attrs) do
    {
      navision_id: 123,
      first_name: 'Max',
      last_name: 'Muster',
      email: 'max.muster@example.com',
      gender: 'Weiblich',
      language: 'DES',
      beitragskategorie: 'EINZEL',
      birthday: 40.years.ago.to_date
    }
  end
  subject(:member) { described_class.new(attrs, group: group, emails: emails) }

  before { travel_to(Time.zone.local(2022, 10, 20, 11, 11)) }

  it '#person does not persist person' do
    attrs[:phone_mobile] = '079 000 00 00'
    expect { member.person }.not_to change { Person.count }
  end

  describe 'validations' do
    it 'is valid with birthday 6 years ago' do
      attrs[:birthday] = 6.years.ago
      expect(member).to be_valid
      expect(member.errors).to be_empty
    end

    it 'is invalid with birthday 6 years ago' do
      attrs[:birthday] = (5.years + 11.month).ago
      expect(member).not_to be_valid
      expect(member.errors).to eq 'Max Muster(123): Rollen ist nicht gültig, Person muss ein Geburtsdatum haben ' \
        'und mindestens 6 Jahre alt sein'

    end

    it 'is invalid without birthday' do
      attrs[:birthday] = nil
      expect(member).not_to be_valid
      expect(member.errors).to eq 'Max Muster(123): Rollen ist nicht gültig, Person muss ein Geburtsdatum haben ' \
        'und mindestens 6 Jahre alt sein'
    end

    it 'is invalid without group' do
      member = described_class.new(attrs.merge(birthday: 6.years.ago), group: nil)
      expect(member).not_to be_valid
      expect(member.errors).to eq 'Max Muster(123): Rollen ist nicht gültig, Group muss ausgefüllt werden'
    end

    it 'is invalid with member_type Abonnent' do
      attrs[:member_type] = 'Abonnent'
      expect(member).not_to be_valid
      expect(member.errors).to eq 'Max Muster(123): Abonnent ist nicht gültig'
    end
  end

  describe 'person attributes' do
    subject(:person) { member.person }

    it 'sets confirmed_at to skip devise confirmation email' do
      expect(person.confirmed_at).to eq Time.zone.at(0)
    end

    it 'assigns attributes to existing person found by navision_id' do
      Fabricate(:person, id: 123)
      attrs[:navision_id] = 123
      attrs[:first_name] = :test
      expect(person.first_name).to eq 'test'
      expect(person.primary_group).to eq group
    end

    it 'sets various attributes via through values' do
      attrs[:first_name] = :first
      attrs[:last_name] = :last
      attrs[:zip_code] = 3000
      attrs[:town] = :town
      attrs[:country] = 'CH'
      attrs[:birthday] = '1.1.2000'
      attrs[:gender] = 'Männlich'
      attrs[:language] = 'DES'
      expect(person.first_name).to eq 'first'
      expect(person.last_name).to eq 'last'
      expect(person.zip_code).to eq '3000'
      expect(person.town).to eq 'town'
      expect(person.country).to eq 'CH'
      expect(person.gender).to eq 'm'
      expect(person.language).to eq 'de'
      expect(person.birthday).to eq Date.new(2000, 1, 1)
      expect(person).to be_valid
    end

    it 'sets combined address attributes' do
      attrs[:address_supplement] = "test"
      attrs[:address] = "Landweg 1a"
      attrs[:postfach] = 3000
      expect(person.address).to eq <<~TEXT.strip
        test
        Landweg 1a
        3000
      TEXT
    end

    it 'sets email to nil if email is included in passed emails array' do
      emails << 'test@example.com'
      attrs[:email] = 'test@example.com'
      expect(member).to be_valid
      expect(member.person.email).to be_blank
    end
  end

  describe 'phone numbers' do
    subject(:numbers) { member.person.phone_numbers }

    it 'sets phone numbers' do
      attrs[:phone] = '079 12 123 10'
      attrs[:phone_mobile] = '079 12 123 11'
      attrs[:phone_direct] = '079 12 123 12'
      expect(numbers).to have(3).items

      expect(numbers[0][:label]).to eq 'Privat'
      expect(numbers[1][:label]).to eq 'Mobil'
      expect(numbers[2][:label]).to eq 'Direkt'
      expect(numbers[0][:number]).to eq '079 12 123 10'
      expect(numbers[1][:number]).to eq '079 12 123 11'
      expect(numbers[2][:number]).to eq '079 12 123 12'

      expect(numbers.collect(&:public).uniq).to eq [true]
    end

    it 'ignores invalid phone numbers' do
      attrs[:phone] = '123'
      attrs[:phone_mobile]  = '079 12 34 560'
      expect(numbers).to have(1).item
      expect(numbers.first.number).to eq '079 12 34 560'
    end
  end

  describe 'roles' do
    subject(:role) { member.person.roles.first }

    before { attrs.merge!(beitragskategorie: 'EINZEL', birthday: 10.years.ago) }

    it 'sets expected type and group' do
      expect(role.group).to eq group
      expect(role.type).to eq 'Group::SektionsMitglieder::Mitglied'
      expect(role).to be_valid
      expect(role.beitragskategorie).to eq 'einzel'
    end

    it 'reads only created_at' do
      attrs[:role_created_at] = '1.1.1960'
      attrs[:role_deleted_at] = '1.1.1990'
      expect(role.created_at).to eq Date.new(1960, 1, 1)
      expect(role.deleted_at).to be_nil
      expect(role).to be_valid
    end

    it 'reads deleted_at only if member_type is Ausgetreten' do
      attrs[:role_deleted_at] = '1.1.1990'
      attrs[:member_type] = 'Ausgetreten'
      expect(role.deleted_at).to eq Date.new(1990, 1, 1)
    end

    it 'does not set deleted_at if member_type is Ausgetreten and timestamp cannot be parsed' do
      attrs[:role_deleted_at] = 'asdf'
      attrs[:member_type] = 'Ausgetreten'
      expect(role.deleted_at).to be_nil
    end

    {
      einzel: 'EINZEL',
      jugend: 'JUGEND',
      familie: ['FAMILIE', 'FREI KIND', 'FREI FAM'],
    }.each do |kind, values|
      Array(values).each do |value|
        it "sets role beitragskategorie to #{kind} for #{value}" do
          attrs[:beitragskategorie] = value
          expect(role.beitragskategorie.to_sym).to eq(kind)
        end
      end
    end
  end
end
