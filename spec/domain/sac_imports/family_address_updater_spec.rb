# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::FamilyAddressUpdater do
  subject(:updater) { described_class.new(output: double(puts: nil)) }

  context "when updating all families" do
    before do
      5.times do |iteration| # Create 5 families with random configurations
        main_person = create_family_member(iteration, sac_family_main_person: true)

        Array.new(rand(1..5)) do
          create_family_member(main_person.household_key)
        end
      end
    end

    it "ensures all household members share the same address as their main person after update" do
      updater.update

      Person.where(sac_family_main_person: true).find_each do |main_person|
        mismatched_members = Person.where(household_key: main_person.household_key)
          .where.not(main_person.address_attrs)

        expect(mismatched_members).to be_empty
      end
    end
  end

  context "when main person has invalid address" do
    let!(:main_person) {
      create_family_member(1, sac_family_main_person: true,
        birthday: 50.years.ago).tap do |person|
        person.update_columns(street: nil, postbox: nil)
      end
    }
    let!(:family_member) {
      create_family_member(main_person.household_key,
        birthday: 40.years.ago)
    }
    let!(:young_family_member) {
      create_family_member(main_person.household_key,
        birthday: 30.years.ago)
    }

    it "uses adress of oldest household member" do
      expected_address_attrs = family_member.address_attrs
      updater.update

      expect(main_person.reload.address_attrs).to eq expected_address_attrs
      expect(young_family_member.reload.address_attrs).to eq expected_address_attrs
    end
  end

  it "creates versions even with paper trail globally disabled " do
    expect(PaperTrail.enabled?).to be_falsey

    main_person = create_family_member(1, sac_family_main_person: true)
    family_member = create_family_member(main_person.household_key)

    expect { updater.update }.to change { PaperTrail::Version.count }.by(1)
    expect(family_member.versions).to have(1).item # Family member was updated with new address
  end

  def create_family_member(household_key, sac_family_main_person: false, **attrs)
    Fabricate(:person,
              **attrs.reverse_merge(
                sac_family_main_person: sac_family_main_person,
                household_key: household_key,
                street: Faker::Address.street_name,
                housenumber: Faker::Address.building_number,
                postbox: Faker::Address.secondary_address,
                zip_code: Faker::Address.zip,
                town: Faker::Address.city,
                # hardcode to make sure it is not CH, otherwise the zip is validated -> flaky specs
                country: "LI"
              ))
  end
end
