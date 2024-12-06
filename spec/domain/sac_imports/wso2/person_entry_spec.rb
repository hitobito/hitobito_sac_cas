# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Wso2::PersonEntry do
  let(:source) { SacImports::CsvSource::SOURCES[:WSO21] }
  let(:data) { source.new(**row.reverse_merge(source.members.index_with(nil))) }

  let(:row) do
    {
      um_id: 42,
      wso2_legacy_password_hash: "UM_USER_PASSWORD",
      wso2_legacy_password_salt: "UM_SALT_VALUE",
      navision_id: people(:mitglied).id.to_s,
      gender: "FRAU",
      first_name: "Maxime",
      last_name: "Muster",
      address_care_of: "Addresszusatz",
      address: "Strasse 42",
      postbox: "Postfach",
      town: "Ort",
      zip_code: " 3000 ",
      country: "CH",
      phone: "+41 79 123 45 67",
      phone_business: "+41 31 123 45 67",
      language: "E",
      email: "maxime.muster@example.com",
      birthday: 40.years.ago.to_date,
      email_verified: "1",
      role_basiskonto: "1",
      role_abonnent: "0",
      role_gratisabonnent: "0"
    }
  end

  let(:existing_emails) { Concurrent::Set.new(Person.pluck(:email).compact) }
  let(:basic_login_group) { Group::AboBasicLogin.create!(parent: groups(:abos)) }
  let(:abo_group) { Group::AboTourenPortal.create!(parent: groups(:abos)) }

  subject(:entry) { described_class.new(data, basic_login_group, abo_group, existing_emails) }

  describe "#um_id_tag" do
    it "includes the um_id" do
      expect(row[:um_id]).to be_present
      expect(entry.um_id_tag).to eq("UM-ID-#{row[:um_id]}")
    end
  end

  describe "#gender" do
    it "returns 'm' for 'HERR'" do
      row[:gender] = "HERR"
      expect(entry.gender).to eq("m")
    end

    it "returns 'w' for 'FRAU'" do
      row[:gender] = "FRAU"
      expect(entry.gender).to eq("w")
    end

    it "returns nil for 'FIRMA'" do
      row[:gender] = "FIRMA"
      expect(entry.gender).to be_nil
    end

    it "returns nil for nil" do
      row[:gender] = nil
      expect(entry.gender).to be_nil
    end
  end

  describe "validations" do
    describe "valid_gender" do
      it "is valid without gender" do
        row[:gender] = nil
        expect(entry).to be_valid
      end

      ["HERR", "FRAU", "FIRMA"].each do |gender|
        it "is valid with gender #{gender}" do
          row[:gender] = gender
          expect(entry).to be_valid
        end
      end

      it "is invalid with an invalid gender" do
        row[:gender] = "INVALID"
        expect(entry).not_to be_valid
        expect(entry.errors_on(:gender)).to include("INVALID is not a valid gender")
      end
    end

    describe "at_least_one_role" do
      context "with a new person" do
        let(:person) { Person.new }

        before { allow(entry).to receive(:person).and_return(person) }

        it "adds error on roles without a role" do
          expect(person.roles).to be_empty
          entry.validate
          expect(entry.errors_on(:roles)).to include("can't be empty")
        end

        it "does not add error on roles with a role" do
          person.roles.build(
            type: Group::AboBasicLogin::BasicLogin.sti_name,
            group: basic_login_group
          )
          entry.validate
          expect(entry.errors_on(:roles)).to be_empty
        end
      end

      context "with an existing person" do
        let(:person) { Fabricate(:person) }

        before { allow(entry).to receive(:person).and_return(person) }

        it "does not add error on roles without a role" do
          expect(person.roles).to be_empty
          expect(entry).to be_valid
        end
      end
    end

    describe "person_must_exist_if_navision_id_is_present" do
      it "adds error on base if navision_id is present but person can't be found" do
        row[:navision_id] = Person.maximum(:id) + 1 # non-existing id
        entry.validate
        expect(entry.errors_on(:base)).to include("navision_id present put person not found")
      end

      it "is valid with a person" do
        row[:navision_id] = people(:mitglied).id.to_s
        entry.validate
        expect(entry.errors_on(:base)).to be_empty
      end
    end
  end

  describe "#person" do
    it "#person does not persist person" do
      expect(entry).to be_valid
      expect { entry.person }.not_to(change { Person.count })
    end

    context "when navision_id is present" do
      it "finds the person by id" do
        row[:navision_id] = people(:mitglied).id.to_s
        expect(entry.person).to eq(people(:mitglied))
      end

      it "returns new person if the person can't be found" do
        row[:navision_id] = "-42"
        expect(entry.person).to be_new_record
      end
    end

    context "when navision_id is absent" do
      before do
        row[:navision_id] = nil
        row[:um_id] = "42"
      end

      it "finds the person by email" do
        row[:email] = people(:mitglied).email
        expect(entry.person).to eq(people(:mitglied))
      end

      it "finds the person by tag" do
        people(:mitglied).update!(tag_list: "UM-ID-42")
        expect(entry.person).to eq(people(:mitglied))
      end

      it "returns new person if the person can't be found" do
        expect(entry.person).to be_new_record
      end
    end

    describe "assigns attributes" do
      context "with existing person" do
        let(:existing_person) { people(:mitglied) }

        before { row[:navision_id] = existing_person.id.to_s }

        it "assigns legacy password attributes" do
          expect(entry.person.wso2_legacy_password_hash).to eq("UM_USER_PASSWORD")
          expect(entry.person.wso2_legacy_password_salt).to eq("UM_SALT_VALUE")
        end

        it "with email_verified=1 assigns confirmed_at and correspondence" do
          existing_person.update_columns(confirmed_at: nil, correspondence: "print")
          row[:email_verified] = "1"
          expect(entry.person.confirmed_at).to eq(Time.zone.at(0))
          expect(entry.person.correspondence).to eq("digital")
        end

        it "with email_verified != 1 does not assign confirmed_at and correspondence" do
          existing_person.update_columns(confirmed_at: nil, correspondence: "print")
          row[:email_verified] = "anything else"
          expect(entry.person.confirmed_at).to be_nil
          expect(entry.person.correspondence).to eq("print")
        end

        it "assigns tag" do
          expect(people(:mitglied).tag_list).not_to include("UM-ID-42")
          expect(entry.person.tag_list).to include("UM-ID-42")
        end

        describe "email" do
          it "assigns the email" do
            people(:mitglied).update!(email: nil)
            expect(entry.person.email).to eq(row[:email])
            expect(entry.warning).to be_blank
          end

          it "overwrites the email" do
            expect(entry.person).to eq people(:mitglied)
            expect(entry.person.email).to eq row[:email]
            expect(entry.person).to be_email_changed
            expect(entry.warning).to match(/Email mismatch, overwriting current email/)
          end

          it "adds additional_email if the email is already taken" do
            row[:email] = people(:familienmitglied).email # email of another person record
            expect(entry.person.email).not_to eq row[:email]
            expect(entry.person.additional_emails.map(&:email)).to eq [row[:email]]
            expect(entry.warning).to eq(
              "Email #{row[:email]} already exists in the system, importing with additional_email."
            )
          end
        end

        it "does not assign person attributes" do
          expect(entry.person.first_name).to eq(existing_person.first_name)
          expect(entry.person.last_name).to eq(existing_person.last_name)
          expect(entry.person.town).to eq(existing_person.town)
          expect(entry.person.language).to eq(existing_person.language)
        end
      end

      context "with new person" do
        before { row[:navision_id] = nil }

        it "assigns legacy password attributes" do
          expect(entry.person.wso2_legacy_password_hash).to eq("UM_USER_PASSWORD")
          expect(entry.person.wso2_legacy_password_salt).to eq("UM_SALT_VALUE")
        end

        it "with email_verified=1 assigns confirmed_at and sets correspondence" do
          row[:email_verified] = "1"
          expect(entry.person.confirmed_at).to eq(Time.zone.at(0))
          expect(entry.person.correspondence).to eq("digital")
        end

        it "with email_verified != 1 does not assign confirmed_at and sets correspondence" do
          row[:email_verified] = "anything else"
          expect(entry.person.confirmed_at).to be_nil
          expect(entry.person.correspondence).to eq("print")
        end

        it "assigns tag" do
          expect(entry.person.tag_list).to include("UM-ID-42")
        end

        describe "email" do
          it "assigns the email" do
            expect(entry.person.email).to eq(row[:email])
            expect(entry.warning).to be_blank
          end
        end

        describe "phone_numbers" do
          it "assigns phone numbers" do
            expect(entry.person.phone_numbers.map(&:number)).to match_array [
              row[:phone],
              row[:phone_business]
            ]
          end

          it "adds invalid phone number as note" do
            row[:phone] = "invalid"
            expect(entry.person.phone_numbers.map(&:number)).to eq [row[:phone_business]]
            expect(entry.person.notes.map(&:text)).to eq [
              "Importiert mit ungültiger Telefonnummer Haupt-Telefon: 'invalid'"
            ]
          end
        end

        it "assigns person attributes" do
          expect(entry.person.first_name).to eq row[:first_name]
          expect(entry.person.last_name).to eq row[:last_name]
          expect(entry.person.address_care_of).to eq row[:address_care_of]
          expect(entry.person.postbox).to eq row[:postbox]
          expect(entry.person.address).to eq row[:address]
          expect(entry.person.street).to eq "Strasse"
          expect(entry.person.housenumber).to eq "42"
          expect(entry.person.country).to eq row[:country]
          expect(entry.person.town).to eq row[:town]
          expect(entry.person.zip_code).to eq row[:zip_code].strip
          expect(entry.person.birthday).to eq row[:birthday]
          expect(entry.person.gender).to eq "w"
          expect(entry.person.language_was).not_to eq "en"
          expect(entry.person.language).to eq "en"
        end
      end
    end

    describe "assigns roles" do
      context "with existing person" do
        it "assigns basiskonto role" do
          row[:navision_id] = people(:tourenchef).id.to_s
          row[:role_basiskonto] = "1"
          row[:role_abonnent] = "0"
          row[:role_gratisabonnent] = "0"
          expect(entry.person.roles.map(&:type))
            .to include Group::AboBasicLogin::BasicLogin.sti_name
        end

        it "does not assign basiskonto role for member person" do
          row[:navision_id] = people(:mitglied).id.to_s
          row[:role_basiskonto] = "1"
          expect(entry.person.roles.map(&:type))
            .not_to include Group::AboBasicLogin::BasicLogin.sti_name
        end

        it "assigns abonnent role" do
          row[:navision_id] = people(:tourenchef).id.to_s
          row[:role_basiskonto] = "0"
          row[:role_abonnent] = "1"
          row[:role_gratisabonnent] = "0"
          expect(entry.person.roles.map(&:type))
            .to include Group::AboTourenPortal::Abonnent.sti_name
        end

        it "assigns gratisabonnent role" do
          row[:navision_id] = people(:tourenchef).id.to_s
          row[:role_basiskonto] = "0"
          row[:role_abonnent] = "0"
          row[:role_gratisabonnent] = "1"
          expect(entry.person.roles.map(&:type))
            .to include Group::AboTourenPortal::Gratisabonnent.sti_name
        end

        it "assigns multiple roles" do
          row[:navision_id] = people(:tourenchef).id.to_s
          row[:role_basiskonto] = "1"
          row[:role_abonnent] = "1"
          row[:role_gratisabonnent] = "1"
          expect(entry.person.roles.map(&:type)).to include(
            Group::AboBasicLogin::BasicLogin.sti_name,
            Group::AboTourenPortal::Abonnent.sti_name,
            Group::AboTourenPortal::Gratisabonnent.sti_name
          )
        end

        it "does not assign duplicate roles" do
          person = people(:tourenchef)
          person.roles.create!(
            type: Group::AboBasicLogin::BasicLogin.sti_name,
            group: basic_login_group
          )
          person.roles.create!(
            type: Group::AboTourenPortal::Abonnent.sti_name,
            group: abo_group
          )
          person.roles.create!(
            type: Group::AboTourenPortal::Gratisabonnent.sti_name,
            group: abo_group
          )
          original_roles = person.roles.map(&:type)

          row[:navision_id] = person.id.to_s
          row[:role_basiskonto] = "1"
          row[:role_abonnent] = "1"
          row[:role_gratisabonnent] = "1"
          expect(entry.person.roles.map(&:type)).to match_array original_roles
        end
      end

      context "with new person" do
        before { row[:navision_id] = nil }

        it "assigns basiskonto role" do
          row[:role_basiskonto] = "1"
          row[:role_abonnent] = "0"
          row[:role_gratisabonnent] = "0"
          expect(entry.person.roles.map(&:type)).to eq [Group::AboBasicLogin::BasicLogin.sti_name]
        end

        it "assigns abonnent role" do
          row[:role_basiskonto] = "0"
          row[:role_abonnent] = "1"
          row[:role_gratisabonnent] = "0"
          expect(entry.person.roles.map(&:type)).to eq [Group::AboTourenPortal::Abonnent.sti_name]
        end

        it "assigns gratisabonnent role" do
          row[:role_basiskonto] = "0"
          row[:role_abonnent] = "0"
          row[:role_gratisabonnent] = "1"
          expect(entry.person.roles.map(&:type)).to eq [Group::AboTourenPortal::Gratisabonnent.sti_name]
        end

        it "assigns multiple roles" do
          row[:role_basiskonto] = "1"
          row[:role_abonnent] = "1"
          row[:role_gratisabonnent] = "1"
          expect(entry.person.roles.map(&:type)).to match_array [
            Group::AboBasicLogin::BasicLogin.sti_name,
            Group::AboTourenPortal::Abonnent.sti_name,
            Group::AboTourenPortal::Gratisabonnent.sti_name
          ]
        end
      end
    end
  end

  describe "#valid?" do
    it "validates the person and adds errors to self" do
      allow(entry).to receive(:person).and_return(Person.new)
      expect(entry.valid?).to be_falsey
      expect(entry.person.errors_on(:base)).to include "Bitte geben Sie einen Namen ein"
      expect(entry.errors_on(:base)).to include "Bitte geben Sie einen Namen ein"
    end

    it "validates the roles" do
      entry.person.roles.build
      expect(entry).not_to be_valid
      expect(entry.errors.messages).to eq(
        roles: ["ist nicht gültig"],
        group: ["muss ausgefüllt werden"],
        type: ["muss ausgefüllt werden"]
      )
    end
  end

  describe "#error_messages" do
    it "returns all error messages and warnings" do
      row[:email] = people(:mitglied).email # don't generate a warning for email mismatch
      entry.errors.add(:base, "base error")
      entry.errors.add(:roles, "roles error")
      entry.send(:warn, "a random warning text")
      entry.send(:warn, "another warning")

      expect(entry.error_messages).to eq(
        "base error, Roles roles error, a random warning text / another warning"
      )
    end
  end

  describe "#import!" do
    context "with a new person" do
      before { row[:navision_id] = nil }

      it "creates the person and roles" do
        expect(entry.import!).to be_truthy
        expect(entry.person).to be_persisted
        expect(entry.person.roles).to be_present
        expect(entry.person.roles).to all(be_persisted)
      end
    end

    context "with an existing person" do
      let(:existing_person) { people(:tourenchef) }

      before { row[:navision_id] = existing_person.id.to_s }

      it "updates the person and assigns roles" do
        expect(entry.import!).to be_truthy
        expect(existing_person.reload).to be_wso2_legacy_password_hash
        expect(existing_person.roles).to include Group::AboBasicLogin::BasicLogin
      end
    end
  end
end
