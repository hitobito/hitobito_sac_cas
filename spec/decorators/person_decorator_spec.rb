# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe PersonDecorator do
  let(:person) do
    Fabricate.build(:person, {
      id: 123,
      first_name: "Max",
      last_name: "Muster",
      nickname: "Maxi",
      zip_code: 8000,
      town: "Zürich",
      birthday: "14.2.2014"
    })
  end

  describe "#as_typeahead" do
    subject(:label) { person.decorate.as_typeahead[:label] }

    it "has id and label" do
      expect(person.decorate.as_typeahead[:id]).to eq 123
      expect(person.decorate.as_typeahead[:label]).to be_present
    end

    it "includes town and year of birth" do
      expect(label).to eq "Max Muster / Maxi, Zürich (2014; 123)"
    end

    it "ommits year of birth if missing" do
      person.birthday = nil
      expect(label).to eq "Max Muster / Maxi, Zürich (123)"
    end

    it "ommits town if missing" do
      person.town = nil
      expect(label).to eq "Max Muster / Maxi (2014; 123)"
    end

    it "ommits town if missing" do
      person.company = true
      person.company_name = "Coorp"
      expect(label).to eq "Coorp, Zürich (Max Muster) (2014; 123)"
    end
  end

  describe "#as_quicksearch" do
    subject(:label) { person.decorate.as_quicksearch[:label] }

    it "includes membership_number" do
      expect(label).to eq "Max Muster / Maxi, Zürich (2014; #{person.membership_number})"
    end
  end

  describe "#login_status_icons" do
    let(:login_status_icon) { person.decorate.login_status_icon }

    it "uses active login icon with warning color for legacy wso2 password hash" do
      person.encrypted_password = nil
      person.wso2_legacy_password_hash = "123"
      person.wso2_legacy_password_salt = "456"

      # rubocop:todo Layout/LineLength
      expect(login_status_icon).to eq '<i title="Altes SAC Passwort (WSO2)" class="text-warning fas fa-user-check"></i>'
      # rubocop:enable Layout/LineLength
    end

    it "does not use any color classes for non legacy wso2 login status" do
      expect(login_status_icon).to eq '<i title="Kein Login" class="fas fa-user-slash"></i>'
    end
  end
end
