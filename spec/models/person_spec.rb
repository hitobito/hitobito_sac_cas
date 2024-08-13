# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Person do
  context "family_id" do
    let(:group) { groups(:bluemlisalp_mitglieder) }
    let(:person) { Fabricate(:person, household_key: "1234ABCD", birthday: 25.years.ago) }

    it "is blank for non family member" do
      assert(person.roles.empty?)
      expect(person.family_id).to be_nil
    end

    it "returns prefixed household_key for person" do
      person = people(:familienmitglied)
      expect(person.family_id).to eq "F#{person.household_key}"
    end
  end

  context "#membership_number (id)" do
    it "is generated automatically" do
      person = Person.create!(first_name: "John")
      expect(person.membership_number).to be_present
    end

    it "can be set for new records" do
      person = Person.create!(first_name: "John", membership_number: 123_123)
      expect(person.reload.id).to eq 123_123
    end

    it "must be unique" do
      Person.create!(first_name: "John", membership_number: 123_123)
      expect { Person.create!(first_name: "John", membership_number: 123_123) }
        .to raise_error(ActiveRecord::RecordNotUnique, /Duplicate entry/)
    end
  end

  context "#membership_years" do
    let(:person) { Fabricate(:person, birthday: Date.parse("01-01-1985")) }

    let(:created_at) { Time.zone.parse("01-01-2000 12:00:00") }
    let(:end_at) { created_at + 364.days }

    def person_with_membership_years
      Person.with_membership_years.find(person.id)
    end

    def create_role(**attrs)
      Fabricate(Group::SektionsMitglieder::Mitglied.name,
        group: groups(:bluemlisalp_mitglieder),
        person: person,
        beitragskategorie: "adult",
        **attrs.reverse_merge(created_at: created_at))
    end

    it "raises error when not using scope :with_membership_years" do
      expect { person.membership_years }
        .to raise_error(RuntimeError, /use Person scope :with_membership_years/)
    end

    it "is 0 for person without membership role" do
      assert(person.roles.empty?)
      expect(person_with_membership_years.membership_years).to eq 0
    end

    it "includes membership_years of deleted roles" do
      create_role(created_at: created_at, deleted_at: end_at)
      expect(person_with_membership_years.membership_years).to eq 1
    end

    it "includes membership_years of archived roles" do
      create_role(created_at: created_at, archived_at: end_at)
      expect(person_with_membership_years.membership_years).to eq 1
    end

    it "includes membership_years of role to be deleted" do
      create_role(created_at: created_at, delete_on: end_at)
      expect(person_with_membership_years.membership_years).to eq 1
    end

    it "with multiple membership roles returns the sum of role.membership_years" do
      create_role(created_at: created_at, delete_on: created_at + 365.days)
      create_role(created_at: created_at + 2.years, delete_on: created_at + 2.years + 365.days)
      expect(person_with_membership_years.membership_years).to eq 2
    end

    it "rounds down to full years" do
      role = create_role(delete_on: created_at + 363.days)
      expect(person_with_membership_years.membership_years).to eq 0

      role.update(delete_on: created_at + 364.days)
      expect(person_with_membership_years.membership_years).to eq 1

      role.update(delete_on: created_at + 728.days)
      expect(person_with_membership_years.membership_years).to eq 1

      role.update(delete_on: created_at + 729.days)
      expect(person_with_membership_years.membership_years).to eq 2

      role.update(delete_on: created_at + 20.years)
      expect(person_with_membership_years.membership_years).to eq 20

      # currently failing
      # role.update(delete_on: created_at + 20.years - 2.days)
      # expect(person_with_membership_years.membership_years).to eq 19
    end
  end

  describe "#salutation_label" do
    subject(:person) { Fabricate.build(:person) }

    ["m", "w", nil].zip(%w[Mann Frau Andere]).each do |value, label|
      it "is #{label} for #{value}" do
        expect(person.salutation_label(value)).to eq label
      end
    end
  end

  describe "membership" do
    subject(:person) { people(:mitglied) }

    it "knows about sektion membership" do
      expect(person).to be_sac_membership_active
      expect(person).to be_sac_membership_anytime
      expect(person.sac_membership_stammsektion_role).to be_present
      expect(person.membership_number).to eq person.id
    end
  end

  describe "navision_id" do
    it "is the same as id" do
      person = Person.create!(first_name: "John")
      expect(person.navision_id).to eq person.id
    end

    it "attribute has the correct column name" do
      expect(Person.human_attribute_name("navision_id")).to eq "Navision-Nr."
    end
  end

  describe "country" do
    it "label falls back to swiss" do
      expect(Person.new(country: "DE").country_label).to eq("Deutschland")
      expect(Person.new.country_label).to eq("Schweiz")
    end

    it "#ignored_country is always false" do
      expect(Person.new(country: "CH").ignored_country?).to eq(false)
      expect(Person.new.ignored_country?).to eq(false)
    end
  end

  describe "correspondence" do
    it "gets set to digital when password is first set" do
      password = "verysafepasswordfortesting"
      person = Fabricate(:person, correspondence: "print")
      expect(person.correspondence).to eq("print")

      person.password = person.password_confirmation = password
      person.save!

      expect(person.correspondence).to eq("digital")
    end

    it "does not set to true when password is updated" do
      password = "verysafepasswordfortesting"
      person = Fabricate(:person, password: password, password_confirmation: password)
      expect(person.correspondence).to eq("digital")

      person.update!(correspondence: "print")

      expect(person.correspondence).to eq("print")

      person.password = person.password_confirmation = "updatedpasswordalsoverysafeyes"
      person.save!

      expect(person.correspondence).to eq("print")
    end
  end

  describe "#sac_tour_guide?" do
    let(:member) do
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
        group: groups(:matterhorn_mitglieder)).person
    end
    let(:tourenkommission) { groups(:matterhorn_touren_und_kurse) }

    before do
      member.qualifications.create!(
        qualification_kind: qualification_kinds(:ski_leader),
        start_at: 1.month.ago
      )
    end

    [Group::SektionsTourenUndKurse::Tourenleiter,
      Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation].each do |role_class|
      it "is tour guide if active #{role_class} role" do
        role_class.create!(person: member, group: tourenkommission)
        expect(member.sac_tour_guide?).to eq(true)
      end
    end

    it "is not tour guide without tour guide role" do
      expect(member.sac_tour_guide?).to eq(false)
    end

    [Group::SektionsTourenUndKurse::Tourenleiter,
      Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation].each do |role_class|
      it "is not tour guide if inactive #{role_class} role" do
        role = role_class.create!(person: member, group: tourenkommission)
        role.update_columns(created_at: 20.years.ago)
        role.destroy!

        expect(member.sac_tour_guide?).to eq(false)
      end
    end
  end

  describe "#backoffice?" do
    let(:geschaeftsstelle) { groups(:geschaeftsstelle) }

    [
      Group::Geschaeftsstelle::Mitarbeiter,
      Group::Geschaeftsstelle::Admin
    ].each do |role_type|
      it "#{role_type} is an backoffice" do
        person = Fabricate(role_type.sti_name, group: geschaeftsstelle).person
        expect(person).to be_backoffice
      end
    end
  end

  it "does not track remark attrs", versioning: true do
    person = people(:admin)
    [
      :sac_remark_section_1,
      :sac_remark_section_2,
      :sac_remark_section_3,
      :sac_remark_section_4,
      :sac_remark_section_5,
      :sac_remark_national_office
    ].each do |attr|
      person.send(:"#{attr}=", attr)
    end
    expect { person.save! }.not_to change { person.versions.count }
  end

  describe "#data_quality" do
    it "is ok by default" do
      person = people(:mitglied)
      expect(person.data_quality).to eq("ok")
      expect(person.data_quality_issues).to eq([])
    end

    it "is set with value and stored as int" do
      person = Fabricate.build(:person, data_quality: "error")
      expect(person.data_quality).to eq("error")
      expect(person[:data_quality]).to eq(3)
    end

    context "on destroy" do
      let(:person) { people(:mitglied) }

      it "is destroys the data quality issues too" do
        expect do
          person.data_quality_issues.create!(attr: "first_name", key: "-", severity: "error")
        end.to change(Person::DataQualityIssue, :count).by(1)
        expect do
          person.destroy!
        end.to change(Person::DataQualityIssue, :count).by(-1)
      end
    end
  end
end
