# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::People::SacRecipientHouseholdRow do
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:person) do
    Fabricate.build(
      :person,
      id: 42,
      first_name: "Hans",
      last_name: "Muster",
      street: "Musterstrasse",
      housenumber: "42",
      zip_code: "4242",
      town: "Musterhausen",
      country: "Schweiz",
      email: "hans.muster@example.com"
    )
  end
  let(:family_member) do
    Fabricate.build(:person,
      id: 43,
      first_name: "Max",
      last_name: "Muster",
      email: "max.muster@example.com",
      street: "Maxweg",
      housenumber: "12",
      household_key: "42")
  end

  subject(:row) { described_class.new(people, group) }

  def value(key) = row.fetch(key)

  describe "person without sac_family/household" do
    let(:people) do
      [person]
    end

    it("id") { expect(value(:id)).to eq 42 }
    it("salutation") { expect(value(:salutation)).to be_nil }
    it("first_name") { expect(value(:first_name)).to eq "Hans" }
    it("last_name") { expect(value(:last_name)).to eq "Muster" }
    it("address_care_of") { expect(value(:address_care_of)).to be_nil }
    it("address") { expect(value(:address)).to eq "Musterstrasse 42" }
    it("postbox") { expect(value(:postbox)).to be_nil }
    it("zip_code") { expect(value(:zip_code)).to eq "4242" }
    it("town") { expect(value(:town)).to eq "Musterhausen" }
    it("email") { expect(value(:email)).to eq "hans.muster@example.com" }
    it("layer_id") do
      expect(value(:layer_id)).to eq groups(:bluemlisalp).id
    end
  end

  describe "person with sac_family/household but other member not in export" do
    let(:people) do
      in_export = person.tap { _1.household_key = "42" }
      family_member

      [in_export]
    end

    it("id") { expect(value(:id)).to eq 42 }
    it("salutation") { expect(value(:salutation)).to be_nil }
    it("first_name") { expect(value(:first_name)).to eq "Hans" }
    it("last_name") { expect(value(:last_name)).to eq "Muster" }
    it("address_care_of") { expect(value(:address_care_of)).to be_nil }
    it("address") { expect(value(:address)).to eq "Musterstrasse 42" }
    it("postbox") { expect(value(:postbox)).to be_nil }
    it("zip_code") { expect(value(:zip_code)).to eq "4242" }
    it("town") { expect(value(:town)).to eq "Musterhausen" }
    it("email") { expect(value(:email)).to eq "hans.muster@example.com" }
    it("layer_id") do
      expect(value(:layer_id)).to eq groups(:bluemlisalp).id
    end
  end

  describe "person with sac_family/household and other member in export" do
    let(:people) do
      in_export1 = person.tap { _1.household_key = "42" }
      in_export2 = Fabricate.build(:person, first_name: "Max", last_name: "Muster", household_key: "42")

      [in_export1, in_export2]
    end

    it("id") { expect(value(:id)).to eq 42 }
    it("salutation") { expect(value(:salutation)).to be_nil }
    it("first_name") { expect(value(:first_name)).to eq "Familie" }
    it("last_name") { expect(value(:last_name)).to eq "Hans und Max Muster" }
    it("address_care_of") { expect(value(:address_care_of)).to be_nil }
    it("address") { expect(value(:address)).to eq "Musterstrasse 42" }
    it("postbox") { expect(value(:postbox)).to be_nil }
    it("zip_code") { expect(value(:zip_code)).to eq "4242" }
    it("town") { expect(value(:town)).to eq "Musterhausen" }
    it("email") { expect(value(:email)).to eq "hans.muster@example.com" }
    it("layer_id") do
      expect(value(:layer_id)).to eq groups(:bluemlisalp).id
    end

    context "with only one person having mail" do
      let(:people) do
        person.household_key = "42"
        person.email = nil

        [person, family_member]
      end

      it("uses id from person with email") { expect(value(:id)).to eq 43 }
      it("uses email from person with email") { expect(value(:email)).to eq "max.muster@example.com" }
      it("uses address from person with email") { expect(value(:address)).to eq "Maxweg 12" }
      it("first_name") { expect(value(:first_name)).to eq "Familie" }
      it("last_name") { expect(value(:last_name)).to eq "Hans und Max Muster" }
    end

    context "with no person having mail" do
      let(:people) do
        person.household_key = "42"
        person.email = nil

        family_member.email = nil

        [person, family_member]
      end

      it("uses id from first person") { expect(value(:id)).to eq 42 }
      it("uses address from first person") { expect(value(:address)).to eq "Musterstrasse 42" }
      it("first_name") { expect(value(:first_name)).to eq "Familie" }
      it("last_name") { expect(value(:last_name)).to eq "Hans und Max Muster" }
    end
  end
end
