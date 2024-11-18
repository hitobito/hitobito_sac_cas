# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::FamilyAddressUpdater do
  context "when updating all families" do
    before do
      5.times.with_index do |iteration| # Create 5 families with random configurations
        main_person = Fabricate(:person, sac_family_main_person: true, household_key: iteration, street: Faker::Address.street_address)
        
        Array.new(rand(1..5)) do
          Fabricate(:person, household_key: main_person.household_key, street: [main_person.street, Faker::Address.street_address].sample)
        end
      end
    end

    it "ensures all household members share the same street as their main person after update" do
      described_class.new.update

      Person.where(sac_family_main_person: true).find_each do |main_person|
        main_street = main_person.street
        mismatched_members = Person.where(household_key: main_person.household_key)
                                    .where.not(street: main_street)

        expect(mismatched_members).to be_empty, "Mismatched streets found for household of main person #{main_person.id}"
      end
    end
  end
end
