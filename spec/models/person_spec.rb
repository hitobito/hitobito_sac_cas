# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Person do
  context "::validations" do
    describe "first_name and last_name" do
      it "are not required" do
        person = Person.new.tap(&:validate)

        expect(person.errors[:first_name]).to be_empty
        expect(person.errors[:last_name]).to be_empty
      end

      it "are not required for company persons" do
        person = Person.new(company: true).tap(&:validate)

        expect(person.errors[:first_name]).to be_empty
        expect(person.errors[:last_name]).to be_empty
      end

      it "are required when having role from SacCas::Person::REQUIRED_FIELDS_ROLES" do
        person = Person.create!(nickname: "dummy")
        role_class = Group::AboMagazin::Abonnent
        expect(SacCas::Person::REQUIRED_FIELDS_ROLES).to include(role_class.sti_name)
        role_class.create!(person:, group: groups(:abo_die_alpen))
        person.validate

        expect(person.errors[:first_name]).to include("muss ausgefüllt werden")
        expect(person.errors[:last_name]).to include("muss ausgefüllt werden")
      end

      it "are not required when having role other than from REQUIRED_FIELDS_ROLES" do
        person = Person.create!(nickname: "dummy")
        role_class = Group::SektionsFunktionaere::Kulturbeauftragter
        expect(SacCas::Person::REQUIRED_FIELDS_ROLES).not_to include(role_class.sti_name)
        role_class.create!(person:, group: groups(:bluemlisalp_funktionaere))
        person.validate

        expect(person.errors[:first_name]).to be_empty
        expect(person.errors[:last_name]).to be_empty
      end

      it "are not required for company person having role from REQUIRED_FIELDS_ROLES" do
        person = Person.create!(nickname: "dummy", company: true, company_name: "Dummy AG")
        role_class = Group::AboMagazin::Abonnent
        expect(SacCas::Person::REQUIRED_FIELDS_ROLES).to include(role_class.sti_name)
        role_class.create!(person:, group: groups(:abo_die_alpen))
        person.validate

        expect(person.errors[:first_name]).to be_empty
        expect(person.errors[:last_name]).to be_empty
      end
    end

    describe "unconfirmed email", :with_truemail_validation do
      let(:person) { people(:mitglied) }

      it "is valid when blank" do
        person.unconfirmed_email = ""
        expect(person).to be_valid
      end

      it "is invalid for invalid formatted email" do
        person.unconfirmed_email = "test"
        expect(person).not_to be_valid
        expect(person.errors.to_a).to eq ["E-Mail ist nicht gültig"]
      end

      it "is invalid for non existing domain" do
        person.unconfirmed_email = "test@missing.hitobito.ch"
        expect(person).not_to be_valid
        expect(person.errors.to_a).to eq ["E-Mail ist nicht gültig"]
      end

      it "is invalid if email is already taken" do
        person.unconfirmed_email = people(:admin).email
        expect(person).not_to be_valid
        expect(person.errors.to_a).to eq ["E-Mail ist nicht gültig"]
      end

      it "is valid if format is valid and no other email exists" do
        person.unconfirmed_email = "test@example.com"
        expect(person).to be_valid
      end
    end
  end

  context "associations" do
    %w[landline mobile].each do |label|
      it "#phone_number_#{label} returns the number with label #{label.inspect}" do
        person = people(:mitglied)
        phone_number = person.phone_numbers.create!(number: "+41791234567", label: label)
        expect(person.send(:"phone_number_#{label}")).to eq(phone_number)
      end
    end
  end

  context "scopes" do
    describe "where_login_matches" do
      let(:person) { people(:mitglied) }

      it "returns person with email" do
        expect(Person.where_login_matches(person.email)).to eq([person])
      end

      it "returns person with membership_number" do
        expect(Person.where_login_matches(person.membership_number)).to eq([person])
      end

      it "returns empty for non-matching login" do
        expect(Person.where_login_matches("nonexisting")).to be_empty
      end

      it "can be chained with other scopes" do
        expect(Person.where_login_matches(person.email).where(confirmed_at: nil)).to be_empty
        # rubocop:todo Layout/LineLength
        expect(Person.where_login_matches(person.email).where.not(confirmed_at: nil)).to eq([person])
        # rubocop:enable Layout/LineLength

        expect(Person.where(confirmed_at: nil).where_login_matches(person.email)).to be_empty
        # rubocop:todo Layout/LineLength
        expect(Person.where.not(confirmed_at: nil).where_login_matches(person.email)).to eq([person])
        # rubocop:enable Layout/LineLength
      end
    end
  end

  context "paper trail", versioning: true do
    let(:person) { people(:admin) }

    it "does not track remark attrs" do
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

    it "does not track wso2 password attrs" do
      person.wso2_legacy_password_hash = "password-hash"
      person.wso2_legacy_password_salt = "password-salt"
      expect { person.save! }.not_to change { person.versions.count }
    end
  end

  context "#family_id" do
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
        .to raise_error(ActiveRecord::RecordNotUnique, /duplicate key/)
    end
  end

  context "#membership_years" do
    let(:person) { Fabricate(:person, birthday: Date.parse("01-01-1985")) }

    let(:start_on) { Time.zone.parse("01-01-2000 12:00:00") }
    let(:end_on) { start_on + 1.years }

    def person_with_membership_years
      Person.with_membership_years.find(person.id)
    end

    def create_role(**attrs)
      Fabricate(Group::SektionsMitglieder::Mitglied.name,
        group: groups(:bluemlisalp_mitglieder),
        person: person,
        beitragskategorie: "adult",
        **attrs.reverse_merge(start_on: start_on))
    end

    it "returns cached_membership_years" do
      person.update!(cached_membership_years: 42)
      expect(person.membership_years).to eq 42
    end

    it "returns db calculated value when used with scope :with_membership_years" do
      person.update!(cached_membership_years: 42)
      create_role(start_on:, end_on: start_on + 7.years)
      expect(person_with_membership_years.membership_years).to eq 7
    end

    it "is 0 for person without membership role" do
      assert(person.roles.empty?)
      expect(person_with_membership_years.membership_years).to eq 0
    end

    it "includes membership_years of deleted roles" do
      create_role(start_on: start_on, end_on: end_on)
      expect(person_with_membership_years.membership_years).to eq 1
    end

    it "includes membership_years of archived roles" do
      create_role(start_on: start_on, archived_at: end_on)
      expect(person_with_membership_years.membership_years).to eq 1
    end

    it "includes membership_years of role to be deleted" do
      create_role(start_on: start_on, end_on: end_on)
      expect(person_with_membership_years.membership_years).to eq 1
    end

    it "with multiple membership roles returns the sum of role.membership_years" do
      create_role(start_on: start_on, end_on: start_on + 365.days)
      create_role(start_on: start_on + 2.years, end_on: start_on + 2.years + 365.days)
      expect(person_with_membership_years.membership_years).to eq 2
    end

    it "multiple roles, with duration of less than a year, add together to membership_years" do
      create_role(start_on: Date.new(2000, 1, 1), end_on: Date.new(2000, 7, 1))
      create_role(start_on: Date.new(2000, 7, 2), end_on: Date.new(2001, 1, 1))
      create_role(start_on: Date.new(2001, 1, 2), end_on: Date.new(2001, 7, 1))
      create_role(start_on: Date.new(2001, 7, 2), end_on: Date.new(2002, 1, 1))
      create_role(start_on: Date.new(2002, 1, 2), end_on: Date.new(2002, 7, 1))
      expect(person_with_membership_years.membership_years).to eq 2
    end

    it "calculates membership years correctly for leap year" do
      create_role(start_on: Date.new(2020, 1, 1), end_on: Date.new(2020, 12, 31))
      expect(person_with_membership_years.membership_years).to eq 1
    end

    it "calculates membership years correctly for leap year when passing reporting date" do
      create_role(start_on: Date.new(2020, 1, 1), end_on: Date.new(2023, 12, 31))
      expect(Person.with_membership_years("people.*",
        Date.new(2020, 12, 31)).find(person.id).membership_years).to eq(0)
      expect(Person.with_membership_years("people.*",
        Date.new(2021, 1, 1)).find(person.id).membership_years).to eq(1)
    end

    it "calculates membership years correctly for two years with one leap year" do
      create_role(start_on: Date.new(2020, 1, 1), end_on: Date.new(2021, 12, 31))
      expect(person_with_membership_years.membership_years).to eq 2
    end

    # rubocop:todo Layout/LineLength
    it "calculates membership years correctly for two years with one leap year when passing reporting date" do
      # rubocop:enable Layout/LineLength
      create_role(start_on: Date.new(2020, 1, 1), end_on: Date.new(2023, 12, 31))
      expect(Person.with_membership_years("people.*",
        Date.new(2021, 12, 31)).find(person.id).membership_years).to eq(1)
      expect(Person.with_membership_years("people.*",
        Date.new(2022, 1, 1)).find(person.id).membership_years).to eq(2)
    end

    it "calculates membership years correctly for the next 20 years" do
      role = create_role(end_on: start_on + 363.days)
      expect(person_with_membership_years.membership_years).to eq 0

      (1..20).each do |x|
        [
          {years_offset: x.years - 2.days, expected_years: x - 1},
          {years_offset: x.years - 1.days, expected_years: x},
          {years_offset: x.years, expected_years: x}
        ].each do |test_case|
          role.update(end_on: role.start_on + test_case[:years_offset])
          expect(person_with_membership_years.membership_years).to eq(test_case[:expected_years])
        end
      end
    end

    it "calculates membership years correctly when passing reporting date" do
      create_role(end_on: start_on + 5.years)
      expect(Person.with_membership_years("people.*",
        Date.new(2001, 12, 31)).find(person.id).membership_years).to eq(1)
      expect(Person.with_membership_years("people.*",
        Date.new(2002, 1, 1)).find(person.id).membership_years).to eq(2)
    end

    it "calculates membership years from roles starting and ending in overlapping years" do
      role = create_role(end_on: Date.new(2000, 0o7, 19))
      role.update!(start_on: Date.new(2000, 0o4, 10))
      expect(person_with_membership_years.membership_years).to eq 0

      role.update(end_on: Date.new(2001, 0o7, 19))
      expect(person_with_membership_years.membership_years).to eq(1)

      role.update(end_on: Date.new(2002, 0o7, 19))
      expect(person_with_membership_years.membership_years).to eq(2)
    end

    it "with multiple roles and using .with_membership_years scope calculates correctly" do
      # membership_years on Person are converted to integers, so we do the same here to find out
      # the expected value for the role
      expected_years = Role.with_membership_years.find(roles(:mitglied).id).membership_years.to_i

      # the person has only one role, so the membership_years should be the same
      years = Person.with_membership_years.find(people(:mitglied).id).membership_years
      expect(years).to eq(expected_years)

      # add a non-membership role that does not count towards the membership_years
      Group::SektionsMitglieder::Ehrenmitglied.create!(
        person: people(:mitglied),
        group: groups(:bluemlisalp_mitglieder),
        start_on: "2020-01-01",
        end_on: Date.current.end_of_year
      )
      # the person has now two roles, so the membership_years should be the same.
      # this expectation makes sure we don't double the membership_years when joining the roles
      years = Person.joins(:roles).with_membership_years.find(people(:mitglied).id).membership_years
      expect(years).to eq(expected_years)
    end
  end

  describe "#salutation_label" do
    subject(:person) { Fabricate.build(:person) }

    ["m", "w", nil].zip(%w[männlich weiblich divers]).each do |value, label|
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

  describe "modifying email" do
    let(:confirmed_at) { Date.current.yesterday.to_datetime }

    subject(:person) { Fabricate(:person, confirmed_at:, correspondence: :digital) }

    it "clearing resets confirmed_at and correspondence" do
      expect do
        person.update!(email: nil)
      end.to change { person.reload.confirmed_at }.from(confirmed_at).to(nil)
        .and change { person.correspondence }.from("digital").to("print")
    end

    it "updating does not affect confirmed_at or correspondence" do
      expect do
        person.update!(email: "test@example.com")
      end.to not_change { person.reload.confirmed_at }
        .and not_change { person.correspondence }
    end
  end

  describe "confirming", versioning: true do
    subject(:person) { Fabricate(:person, confirmed_at: nil, correspondence: :print) }

    it "sets correspondence to digital" do
      expect do
        person.confirm
      end.to change { person.reload.confirmed? }.from(false).to(true)
        .and change { person.correspondence }.from("print").to("digital")
        .and not_change { Delayed::Job.where("handler like '%TransmitPersonJob%'").count }
    end

    it "transmits to abacus if transmittable" do
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: groups(:matterhorn_mitglieder), person:)
      expect do
        person.confirm
      end.to change { person.reload.confirmed? }.from(false).to(true)
        .and change { person.correspondence }.from("print").to("digital")
        .and change { Delayed::Job.where("handler like '%TransmitPersonJob%'").count }.by(1)
    end

    it "reconfirming does not reset changed correspondence value" do
      person.confirm
      person.update!(correspondence: :digital)
      person.update!(correspondence: :print, unconfirmed_email: "test@example.com")
      expect do
        person.confirm
      end.to change { person.reload.email }
        .and change { person.confirmed_at }
        .and not_change { person.correspondence }
    end
  end

  describe "correspondence" do
    subject(:person) { people(:mitglied) }

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

    it "does not set to digital if email is not verified" do
      password = "verysafepasswordfortesting"
      person = Fabricate(:person, correspondence: "print", confirmed_at: nil)
      expect(person.correspondence).to eq("print")

      person.password = person.password_confirmation = password
      person.save!

      expect(person.correspondence).to eq("print")
    end

    it "does not set to digital if password was reset to nil" do
      password = "verysafepasswordfortesting"
      person = Fabricate(:person, correspondence: "print")
      expect(person.correspondence).to eq("print")

      # create paper trail version for password reset
      PaperTrail::Version.create(main: person,
        item: person,
        event: :password_override)

      person.password = person.password_confirmation = password
      person.save!

      expect(person.correspondence).to eq("print")
    end

    context "with wso2 legacy password" do
      let(:salt) { "salt" }
      let(:hash) { generate_wso2_legacy_password_hash(password, salt) }
      let(:password) { "verysafepasswordfortesting" }

      let(:person_template) {
        {correspondence: "print",
         wso2_legacy_password_hash: hash,
         wso2_legacy_password_salt: salt}
      }

      it "does not set to digital if email is not verified" do
        person = Fabricate(:person, person_template.merge(confirmed_at: nil))
        expect(person.correspondence).to eq("print")

        person.valid_password?(password)

        expect(person.correspondence).to eq("print")
      end

      it "does set to digital if email is verified" do
        person = Fabricate(:person, person_template)
        expect(person.correspondence).to eq("print")

        person.valid_password?(password)

        expect(person.correspondence).to eq("digital")
      end
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
        role.update_columns(start_on: 20.years.ago)
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

  describe "#data_quality" do
    let(:person) { people(:mitglied) }

    before do
      person.roles.destroy_all
      People::DataQualityChecker.new(person).check_data_quality
      person.reload
    end

    context "on create" do
      it "is ok by default" do
        expect(person.data_quality_issues).to eq([])
        expect(person.data_quality).to eq("ok")
        expect(person.data_quality_for_database).to eq(0)
      end
    end

    context "on update" do
      it "removes the data_quality_issue if the attribute is valid again" do
        expect do
          person.update!(first_name: nil)
        end.to change(person.data_quality_issues, :count).by(1)
        expect do
          person.update!(first_name: "Puzzle")
        end.to change(person.data_quality_issues, :count).by(-1)
      end

      it "doesn't validate attributes if another attribute that shouldnt be checked is updated" do
        expect do
          person.update!(first_name: nil)
          person.data_quality_issues.destroy_all
          person.update!(sac_remark_section_1: "ignored")
        end.not_to change(person.data_quality_issues, :count)
      end

      describe "person" do
        it "validates the first name" do
          expect do
            person.update!(company_name: nil, first_name: nil)
          end.to change(person.data_quality_issues, :count).by(1)
          expect(person.data_quality_issues.first.message).to eq("Vorname ist leer")
          expect(person.data_quality).to eq("error")
        end

        it "validates the last name" do
          expect do
            person.update!(company_name: nil, last_name: nil)
          end.to change(person.data_quality_issues, :count).by(1)
          expect(person.data_quality_issues.first.message).to eq("Nachname ist leer")
          expect(person.data_quality).to eq("error")
        end
      end

      describe "member" do
        before do
          person.phone_numbers.create!(number: "+41791234567", label: "mobile")
          person.roles.create!(
            type: Group::SektionsMitglieder::Mitglied.sti_name,
            group: groups(:bluemlisalp_mitglieder),
            end_on: Time.zone.tomorrow,
            start_on: Time.zone.now
          )
        end

        it "validates the birthday" do
          expect do
            person.update!(birthday: nil)
          end.to change(person.data_quality_issues, :count).by(1)
          expect(person.data_quality_issues.first.message).to eq("Geburtsdatum ist leer")
          expect(person.data_quality).to eq("error")

          expect do
            person.update!(birthday: Time.zone.today)
          end.not_to change(person.data_quality_issues, :count)
          expect(person.reload.data_quality_issues.first.message)
            .to eq("Geburtsdatum liegt weniger als 6 Jahre vor dem SAC-Eintritt")
          expect(person.data_quality).to eq("warning")
        end

        it "validates the email and phone_numbers" do
          expect do
            person.phone_numbers.destroy_all
            person.update!(email: nil)
          end.to change(person.data_quality_issues, :count).by(2)
          expect(person.data_quality_issues.map(&:message))
            .to include("Telefonnummern ist leer", "Haupt-E-Mail ist leer")
          expect(person.data_quality).to eq("warning")
        end

        it "runs data quality check for phone_numbers" do
          expect { delete_phone_number(person) }.to change(*phone_quality_issue_count(person)).by(1)
          expect(person.data_quality_issues.first.message).to eq("Telefonnummern ist leer")
          expect { add_phone_number(person) }.to change(*phone_quality_issue_count(person)).by(-1)
          expect { delete_phone_number(person) }.to change(*phone_quality_issue_count(person)).by(1)
        end

        def delete_phone_number(person) = person.phone_numbers.destroy_all

        def phone_quality_issue_count(person) = [person.reload.data_quality_issues, :count]

        def add_phone_number(person) = person.phone_numbers.create!(number: "+41791234567",
          label: "mobile")
      end
    end

    context "on destroy" do
      it "is destroys the data quality issues too" do
        expect do
          person.data_quality_issues.create!(attr: "first_name", key: "empty", severity: "error")
        end.to change(Person::DataQualityIssue, :count).by(1)
        expect do
          person.destroy!
        end.to change(Person::DataQualityIssue, :count).by(-1)
      end
    end
  end

  describe "#transmit_data_to_abacus" do
    let(:person) {
      people(:mitglied).tap { |p|
     # rubocop:todo Layout/IndentationWidth
     p.phone_numbers.create!(number: "+41791234567", label: "mobile")
        # rubocop:enable Layout/IndentationWidth
      }
    }
    let(:job) { Delayed::Job.where("handler like '%TransmitPersonJob%'") }

    it "enqueues the job" do
      expect { person.update!(first_name: "Abacus") }.to change(job, :count).by(1)
    end

    it "enqueues the job if email is removed" do
      expect { person.update!(email: "") }.to change(job, :count).by(1)
    end

    # rubocop:todo Layout/LineLength
    it "enqueues the job with an existing abacus_subject_key but without an sac membership invoice" do
      # rubocop:enable Layout/LineLength
      person.roles.destroy_all
      expect {
        person.update!(first_name: "Abacus", abacus_subject_key: 42)
      }.to change(job, :count).by(1)
    end

    it "enqueues the job with an abonnent role" do
      person.roles.destroy_all
      Group::AboMagazin::Abonnent.create!(person: person, group: groups(:abo_die_alpen))
      expect { person.update!(first_name: "Abacus") }.to change(job, :count).by(1)
    end

    it "enqueues the job for the family main person if other member is changed" do
      person = people(:familienmitglied2)
      expect { person.update!(town: "Neuer Ort") }.to change(job, :count).by(1)
      expect(people(:familienmitglied).town).to eq("Neuer Ort")
      # rubocop:todo Layout/LineLength
      expect(job.order(:created_at).last.payload_object.send(:person)).to eq(people(:familienmitglied))
      # rubocop:enable Layout/LineLength
    end

    it "enqueues the job for the family main person if it is changed" do
      person = people(:familienmitglied)
      expect { person.update!(town: "Neuer Ort") }.to change(job, :count).by(1)
      expect(people(:familienmitglied2).town).to eq("Neuer Ort")
      # rubocop:todo Layout/LineLength
      expect(job.order(:created_at).last.payload_object.send(:person)).to eq(people(:familienmitglied))
      # rubocop:enable Layout/LineLength
    end

    it "doesn't enqueue the job if an irrelevant attribute changed" do
      expect { person.update!(additional_information: "Abacus") }.not_to change(job, :count)
    end

    it "doesn't enqueue the job without an sac membership invoice" do
      person.roles.destroy_all
      expect { person.update!(first_name: "Abacus") }.not_to change(job, :count)
    end

    it "doesn't enqueue the job if data quality errors exist" do
      expect { person.update!(birthday: nil) }.not_to change(job, :count)
    end
  end

  describe "#login_status" do
    let(:person) { people(:mitglied) }

    it "does return wso2_legacy_password when wso2_legacy_password is set" do
      person.wso2_legacy_password_hash = "hfg76sdgfg689gsdf"
      person.wso2_legacy_password_salt = "fklsdf71k12123kj9"
      expect(person.login_status).to eq :wso2_legacy_password
    end
  end
end
