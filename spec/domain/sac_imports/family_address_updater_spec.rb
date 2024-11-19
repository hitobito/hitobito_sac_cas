# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::FamilyAddressUpdater do
  context "when updating all families" do
    before do
      5.times do |iteration| # Create 5 families with random configurations
        main_person = build_family_member(iteration, sac_family_main_person: true)

        Array.new(rand(1..5)) do
          build_family_member(main_person.household_key)
        end
      end
    end

    it "ensures all household members share the same address as their main person after update" do
      described_class.new.update

      Person.where(sac_family_main_person: true).find_each do |main_person|
        mismatched_members = Person.where(household_key: main_person.household_key)
          .where.not(main_person.address_attrs)

        expect(mismatched_members).to be_empty
      end
    end
  end

  context "when main person has invalid address" do
    let!(:main_person) { build_family_member(1, sac_family_main_person: true) }
    let!(:family_member) { build_family_member(main_person.household_key) }
    let!(:young_family_member) { build_family_member(main_person.household_key) }

    before do
      young_family_member.update(birthday: family_member.birthday + 10.years)
      young_family_member.reload
      main_person.update_columns(street: nil)
      main_person.reload
    end

    it "uses adress of oldest household member" do
      expected_address_attrs = family_member.address_attrs
      described_class.new.update

      expect(main_person.reload.address_attrs).to eq expected_address_attrs
      expect(young_family_member.reload.address_attrs).to eq expected_address_attrs
    end
  end

  def build_family_member(household_key, sac_family_main_person: false)
    Fabricate(:person,
      sac_family_main_person: sac_family_main_person,
      household_key: household_key,
      street: Faker::Address.street_name,
      housenumber: Faker::Address.building_number,
      postbox: [nil, Faker::Address.secondary_address].sample,
      zip_code: Faker::Address.zip,
      town: Faker::Address.city,
      country: Faker::Address.country_code)
  end
end
