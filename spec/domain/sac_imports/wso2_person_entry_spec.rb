# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Wso2PersonEntry do
  let(:navision_id) { nil }
  let(:email) { "max.muster@example.com" }
  let(:basic_login_group) { Group::AboBasicLogin.create!(parent: groups(:abos)) }
  let(:abo_group) { Group::AboTourenPortal.create!(parent: groups(:abos)) }
  let(:navision_import_group) { Group::ExterneKontakte.create!(name: "Navision Import", parent: Group::SacCas.first!) }
  let(:addition_fields) { {} }
  let(:row) do
    SacImports::CsvSource::SOURCE_HEADERS[:NAV1].keys.index_with { |_symbol| nil }.merge(
      wso2_legacy_password_hash: "foo",
      navision_id: navision_id,
      first_name: "Max",
      last_name: "Muster",
      address: "Ophovenerstrasse 79a",
      zip_code: "2843",
      town: "Neu Carlscheid",
      email: email,
      gender: "HERR",
      language: "D",
      birthday: "01.01.1957",
      **addition_fields
    )
  end

  subject(:entry) { described_class.new(row, basic_login_group, abo_group, navision_import_group) }

  before { travel_to(Time.zone.local(2024, 9, 12, 11, 11)) }

  context "with existing person" do
    let!(:existing_person) { Fabricate(:person) }
    let(:navision_id) { existing_person.id }
    let(:email) { existing_person.email }

    describe "#person" do
      it "does not persist it" do
        expect(entry).to be_valid
        expect { entry.person }
          .to not_change { Person.count }
          .and not_change { existing_person.reload }
      end

      context "if the email doesn't match" do
        let(:email) { "wrong@example.com" }

        it "sets an error accordingly" do
          expect { entry.person }.to(not_change { Person.count })
          expect(entry).not_to be_valid
        end
      end

      context "if the email case doesn't match" do
        let(:email) { existing_person.email.upcase }

        it "doesn't set an error" do
          expect(entry).to be_valid
        end
      end
    end

    describe "#import!" do
      it "does update the person" do
        expect(entry).to be_valid
        expect { entry.import! }
          .to not_change { Person.count }
          .and change { existing_person.reload.wso2_legacy_password_hash }.from(nil).to("foo")
      end

      context "When the person had a Navision ID role" do
        let!(:existing_person) { Fabricate(:person, roles: [Group::ExterneKontakte::Kontakt.new(group: navision_import_group)]) }

        it "does update the person" do
          expect(entry).to be_valid
          expect { entry.import! }
            .to not_change { Person.count }
            .and change { existing_person.reload.wso2_legacy_password_hash }.from(nil).to("foo")
          expect(existing_person.roles.where(type: Group::ExterneKontakte::Kontakt.sti_name)).to eq([])
        end
      end
    end
  end

  context "with new person" do
    describe "#import!" do
      context "when no role flags are set" do
        it "can't import it" do
          expect(entry).not_to be_valid
          expect { entry.import! }
            .to raise_error(ActiveRecord::RecordInvalid)
            .and not_change { Person.count }
            .and not_change { Role.count }
        end
      end

      context "when a single role flag is set" do
        let(:addition_fields) { {role_basiskonto: "1"} }

        it "can import it" do
          expect { entry.person }.to(not_change { Person.count })
          expect(entry).to be_valid
          expect { entry.import! }
            .to change { Person.count }.by(1)
            .and change { Role.count }.by(1)
        end

        it "can import it twice" do
          entry.import!
          # Need to instantiate it freshly, since person is cashed
          entry = described_class.new(row, basic_login_group, abo_group, navision_import_group)
          expect { entry.import! }
            .to not_change { Person.count }
            .and not_change { Role.count }
        end
      end

      context "with garbage phone number" do
        let(:addition_fields) { {role_basiskonto: "1", phone: "garbage"} }

        it "can't import it" do
          expect(entry).not_to be_valid
          expect { entry.import! }
            .to raise_error(ActiveRecord::RecordInvalid)
            .and not_change { Person.count }
            .and not_change { Role.count }
          expect(entry.error_messages).to include("number ist nicht gültig")
        end
      end

      context "with an invalid gender" do
        let(:addition_fields) { {role_basiskonto: "1", gender: "FIRMA"} }

        it "can't import it" do
          expect(entry).not_to be_valid
          expect { entry.import! }
            .to raise_error(ActiveRecord::RecordInvalid)
            .and not_change { Person.count }
            .and not_change { Role.count }
          expect(entry.error_messages).to include("FIRMA is not a valid gender")
        end
      end

      context "when the email is already taken" do
        let!(:existing_person) { Fabricate(:person, email: email) }

        it "can't import it" do
          expect(entry).not_to be_valid
          expect { entry.import! }
            .to raise_error(ActiveRecord::RecordInvalid)
            .and not_change { Person.count }
            .and not_change { Role.count }
          expect(entry.error_messages).to include("Email max.muster@example.com already exists")
        end
      end

      context "when the navision_id can't be found" do
        let(:navision_id) { "123" }

        it "can't import it" do
          expect(entry).not_to be_valid
          expect { entry.import! }
            .to raise_error(ActiveRecord::RecordInvalid)
            .and not_change { Person.count }
            .and not_change { Role.count }
          expect(entry.error_messages).to include("navision_id present put person not found")
        end
      end

      context "when all role flags are set" do
        let(:addition_fields) { {role_basiskonto: "1", role_abonnent: "1", role_gratisabonnent: "1"} }

        it "creates a person with the roles" do
          expect(entry).to be_valid
          expect { entry.import! }
            .to change { Person.count }.by(1)
            .and change { Role.count }.by(3)
        end
      end
    end
  end
end
