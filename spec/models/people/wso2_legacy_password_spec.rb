# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SacCas::People::Wso2LegacyPassword do
  describe "#valid_password?" do
    let(:person) { people(:mitglied) }
    let(:salt) { "salt" }
    let(:hash) { generate_wso2_legacy_password_hash(password, salt) }
    let(:password) { "M" * 12 }

    before do
      person.wso2_legacy_password_hash = hash
      person.wso2_legacy_password_salt = salt
    end

    it "returns true for valid password" do
      expect(person.wso2_legacy_password_hash).to be_present
      expect(person.valid_password?(password)).to be_truthy
      person.reload
      # After the password is set, the legacy password attributes are cleared
      expect(person.wso2_legacy_password_hash).to be_nil
      expect(person.wso2_legacy_password_salt).to be_nil
      expect(person.encrypted_password).to be_present
      expect(person.valid_password?(password)).to be_truthy
    end

    it "returns false for invalid password" do
      expect(person.wso2_legacy_password_hash).to be_present

      expect(person.valid_password?("invalid_password")).to be_falsey
      expect(person.wso2_legacy_password_hash).to be_present
      expect(person.wso2_legacy_password_salt).to be_present
    end

    it "updates password to devise_password also when other person attributes are invalid" do
      person.update_columns(street: nil, zip_code: nil)
      expect {
        person.valid_password?(password)
      }.not_to raise_error
    end
  end

  describe "#password=" do
    let(:person) { people(:mitglied) }
    let(:salt) { "salt" }

    context "with invalid password" do
      let(:short_password) { "Z" * 8 }
      let(:hash) { generate_wso2_legacy_password_hash(short_password, salt) }

      it "does set password even if it is too short" do
        person.wso2_legacy_password_hash = hash
        person.wso2_legacy_password_salt = salt
        expect {
          person.valid_password?(short_password)
        }.not_to raise_error
      end
    end

    context "with valid password" do
      let(:valid_password) { "Z" * 12 }
      let(:hash) { generate_wso2_legacy_password_hash(valid_password, salt) }

      it "does set the password and correspondence if valid" do
        person.update!(wso2_legacy_password_hash: hash, wso2_legacy_password_salt: salt,
          correspondence: "print")

        expect {
          person.valid_password?(valid_password)
        }.to change { person.encrypted_password.present? }.from(false).to(true)
          .and change { person.wso2_legacy_password_hash.present? }.from(true).to(false)
          .and change { person.wso2_legacy_password_salt.present? }.from(true).to(false)
          .and change { person.correspondence }.from("print").to("digital")
      end
    end
  end
end
