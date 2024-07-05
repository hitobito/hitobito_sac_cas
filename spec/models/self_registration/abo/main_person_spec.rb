# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SelfRegistration::Abo::MainPerson do
  subject(:model) { described_class.new }

  let(:required_attrs) {
    {
      first_name: "Max",
      last_name: "Muster",
      email: "max.muster@example.com",
      birthday: "01.01.2000",
      address_care_of: "c/o Musterleute",
      street: "Musterplatz",
      housenumber: "42",
      postbox: "Postfach 23",
      town: "Zürich",
      zip_code: "8000",
      number: "+41 79 123 45 67",
      statutes: "1",
      data_protection: "1"
    }
  }

  describe "default values" do
    it "sets country to CH" do
      expect(model.country).to eq "CH"
    end
  end

  describe "validations" do
    it "is invalid if required attrs are not set" do
      model.country = nil
      expect(model).not_to be_valid
      expect(model.errors.attribute_names).to match_array [
        :first_name,
        :last_name,
        :email,
        :street,
        :housenumber,
        :zip_code,
        :town,
        :birthday,
        :country,
        :number,
        :data_protection,
        :statutes
      ]
    end

    it "is valid if required attrs are set" do
      model.attributes = required_attrs
      expect(model).to be_valid
    end

    it "is invalid if number is invalid" do
      model.attributes = required_attrs.merge(number: "079123")
      expect(model).not_to be_valid
      expect(model.errors.full_messages).to eq ["Telefon ist nicht gültig"]
    end

    it "is invalid if younger than 18" do
      model.attributes = required_attrs.merge(birthday: 17.years.ago.to_date)
      expect(model).not_to be_valid
      expect(model.errors.full_messages).to eq ["Person muss 18 Jahre oder älter sein."]
    end
  end

  describe "#save!" do
    let(:group) { groups(:abo_die_alpen) }

    before do
      group.update!(self_registration_role_type: group.role_types.first)
      model.attributes = required_attrs.merge(primary_group: group)
    end

    it "persists attributes" do
      expect do
        model.save!
      end.to change { Person.count }.by(1)
        .and change { group.roles.count }.by(1)

      person = Person.find_by(email: "max.muster@example.com")
      expect(person.first_name).to eq "Max"
      expect(person.last_name).to eq "Muster"
      expect(person.birthday).to eq Date.new(2000, 1, 1)
      expect(person.address).to eq "Musterplatz 42"
      expect(person.town).to eq "Zürich"
      expect(person.zip_code).to eq "8000"
      expect(person.phone_numbers.first.number).to eq "+41 79 123 45 67"
    end

    describe "newsletter" do
      let(:root) { groups(:root) }
      let!(:list) { Fabricate(:mailing_list, group: root) }

      before do
        root.update!(sac_newsletter_mailing_list_id: list.id)
      end

      it "creates excluding subscription" do
        model.save!
        expect(model.person.subscriptions.excluded.where(mailing_list: list)).to be_exist
      end

      it "does not create excluding subscription if newsletter is set to 1" do
        model.newsletter = 1
        model.save!
        expect(model.person.subscriptions.excluded.where(mailing_list: list)).not_to be_exist
      end

      it "does not fail if list does not exist" do
        list.destroy!
        model.save!
        expect(model.person.subscriptions.excluded.where(mailing_list: list)).not_to be_exist
      end
    end
  end
end
