# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Sektion::Membership do
  let(:navision_id) { 123 }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:attrs) do
    {
      navision_id: navision_id,
      beitragskategorie: "EINZEL",
      last_joining_date: "1.1.1960"
    }
  end
  let(:contact_group) { Group::ExterneKontakte.new(parent: groups(:root), name: "test_contacts") }

  subject(:membership) do
    described_class.new(
      attrs,
      group: group,
      placeholder_contact_group: contact_group,
      current_ability: Ability.new(Person.root)
    )
  end

  before do
    travel_to(Time.zone.local(2022, 10, 20, 11, 11))
    Fabricate(:person, id: navision_id) # Person with same navision_id must exist in db
  end

  describe "validations" do
    it "is invalid without group" do
      member = described_class.new(
        attrs.merge(birthday: 6.years.ago),
        group: nil,
        placeholder_contact_group: contact_group,
        current_ability: Ability.new(Person.root)
      )
      expect(member).not_to be_valid
      expect(member.errors).to match(/Group muss ausgefüllt werden/)
    end

    it "is invalid with member_type Abonnent" do
      attrs[:member_type] = "Abonnent"
      expect(membership).not_to be_valid
      expect(membership.errors).to match(/Abonnent ist nicht gültig/)
    end
  end

  describe "roles" do
    subject(:role) { membership.role }

    before { attrs.merge!(beitragskategorie: "EINZEL", birthday: 10.years.ago) }

    it "sets expected type and group" do
      expect(role.group).to eq group
      expect(role.type).to eq "Group::SektionsMitglieder::Mitglied"
      expect(role).to be_valid
      expect(role.beitragskategorie).to eq "adult"
    end

    it "reads last_joining_date" do
      attrs[:last_joining_date] = "1.1.1960"
      attrs[:last_exit_date] = "1.1.1990"
      expect(role.start_on).to eq Date.parse(attrs[:last_joining_date])
      expect(role.end_on).to eq SacImports::Sektion::Membership::DEFAULT_END_ON
      expect(role).to be_valid
    end

    it "reads last_exit_date only if member_type is Ausgetreten" do
      attrs[:last_exit_date] = "1.1.1990"
      attrs[:member_type] = "Ausgetreten"
      expect(role.end_on).to eq Date.parse(attrs[:last_exit_date])
    end

    it "does not set end_on if member_type is Ausgetreten and timestamp cannot be parsed" do
      attrs[:last_exit_date] = "asdf"
      attrs[:member_type] = "Ausgetreten"
      expect(role.end_on).to be_nil
    end

    {
      adult: "EINZEL",
      youth: "JUGEND",
      family: ["FAMILIE", "FREI KIND", "FREI FAM"]
    }.each do |kind, values|
      Array(values).each do |value|
        it "sets role beitragskategorie to #{kind} for #{value}" do
          attrs[:beitragskategorie] = value
          expect(role.beitragskategorie.to_sym).to eq(kind)
        end
      end
    end
  end

  describe "#import!" do
    {
      adult: "EINZEL",
      youth: "JUGEND",
      family: ["FAMILIE", "FREI KIND", "FREI FAM"]
    }.each do |kind, values|
      Array(values).each do |value|
        it "sets person.sac_family_main_person when raw beitragskategorie value is 'FAMILIE'" do
          attrs[:beitragskategorie] = value
          membership.import!
          expect(membership.role.person.sac_family_main_person).to eq(value == "FAMILIE")
        end
      end
    end
  end
end
