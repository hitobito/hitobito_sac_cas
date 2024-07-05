# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe PeopleManager do
  context "validations" do
    it "does not allow manager and managed to be in different households" do
      manager = Fabricate(:person, household_key: "1234")
      managed = Fabricate(:person, household_key: "5678", birthday: 15.years.ago)
      pm = PeopleManager.new(manager: manager, managed: managed)

      expect(pm).to_not be_valid
      expect(pm.errors.errors).to include(have_attributes(
        attribute: :managed_id,
        type: :in_different_household,
        options: {name: "#{managed.first_name} #{managed.last_name}"}
      ))
    end

    it "allows manager and managed to be in the same household" do
      manager = Fabricate(:person, household_key: "1234", birthday: 25.years.ago)
      managed = Fabricate(:person, household_key: "1234", birthday: 15.years.ago)
      expect(PeopleManager.new(manager: manager, managed: managed)).to be_valid
    end

    it "allows manager or managed to have no household_key" do
      manager = Fabricate(:person, household_key: nil, birthday: 25.years.ago)
      managed = Fabricate(:person, household_key: "1234", birthday: 15.years.ago)
      expect(PeopleManager.new(manager: manager, managed: managed)).to be_valid

      manager = Fabricate(:person, household_key: "1234", birthday: 25.years.ago)
      managed = Fabricate(:person, household_key: nil, birthday: 15.years.ago)
      expect(PeopleManager.new(manager: manager, managed: managed)).to be_valid

      manager = Fabricate(:person, household_key: nil, birthday: 25.years.ago)
      managed = Fabricate(:person, household_key: nil, birthday: 15.years.ago)
      expect(PeopleManager.new(manager: manager, managed: managed)).to be_valid
    end

    it "does not allow manager to be a child" do
      manager = Fabricate(:person, birthday: 15.years.ago)
      managed = Fabricate(:person, birthday: 15.years.ago)
      pm = PeopleManager.new(manager: manager, managed: managed)

      expect(pm).to_not be_valid
      expect(pm.errors.errors).to include(have_attributes(
        attribute: :manager_id,
        type: :manager_is_not_adult,
        options: {name: manager.full_name.to_s, age: manager.years}
      ))
    end

    it "does not allow managed to be an adult" do
      manager = Fabricate(:person, birthday: 25.years.ago)
      managed = Fabricate(:person, birthday: 25.years.ago)
      pm = PeopleManager.new(manager: manager, managed: managed)

      expect(pm).to_not be_valid
      expect(pm.errors.errors).to include(have_attributes(
        attribute: :managed_id,
        type: :managed_is_not_child,
        options: {name: managed.full_name.to_s, age: managed.years}
      ))
    end

    it "allows managed to be a baby" do
      manager = Fabricate(:person, birthday: 25.years.ago)
      managed = Fabricate(:person, birthday: 1.years.ago)
      expect(PeopleManager.new(manager: manager, managed: managed)).to be_valid
    end
  end
end
