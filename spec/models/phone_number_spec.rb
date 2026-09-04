# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe PhoneNumber do
  let(:landline_category) { contact_account_categories(:phone_number_person_landline) }
  let(:mobile_category) { contact_account_categories(:phone_number_person_mobile) }

  it "::FIXED_SLOT_KEYS" do
    expect(SacPhoneNumbers::FIXED_SLOT_KEYS).to eq(%w[landline mobile])
  end

  context "validations" do
    let(:contactable) { people(:mitglied) }
    let(:phone_number) { PhoneNumber.new(contactable:, number: "0780000000") }

    describe "category" do
      it "accepts the fixed slot categories" do
        [landline_category, mobile_category].each do |category|
          phone_number.category = category
          expect(phone_number).to be_valid
        end
      end

      it "rejects other categories" do
        phone_number.category = contact_account_categories(:phone_number_person_other)
        expect(phone_number).not_to be_valid
        expect(phone_number.errors[:category]).to include("ist kein gültiger Wert")
      end

      it "validates presence of category" do
        expect(phone_number).not_to be_valid
        expect(phone_number.errors[:category]).to include("muss ausgefüllt werden")
      end

      it "validates uniqueness of category scoped to contactable_type and contactable_id" do
        _existing_phone_number = PhoneNumber.create!(
          contactable: people(:mitglied),
          category: landline_category,
          number: "0780000000"
        )

        phone_number.category = landline_category
        expect(phone_number).not_to be_valid
        expect(phone_number.errors[:category_id]).to include("ist bereits vergeben")

        phone_number.category = mobile_category
        expect(phone_number).to be_valid
      end
    end
  end
end
