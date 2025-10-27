# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe PhoneNumber do
  it "::predefined_labels" do
    expect(PhoneNumber.predefined_labels).to eq(%w[landline mobile])
  end

  context "validations" do
    let(:contactable) { people(:mitglied) }
    let(:phone_number) { PhoneNumber.new(contactable:, number: "0780000000") }

    describe "label" do
      it "accepts predefined labels" do
        PhoneNumber.predefined_labels.each do |label|
          phone_number.label = label
          expect(phone_number).to be_valid
        end
      end

      it "rejects other labels" do
        phone_number.label = "invalid_label"
        expect(phone_number).not_to be_valid
        expect(phone_number.errors[:label]).to include("ist kein gültiger Wert")
      end

      it "validates presence of label" do
        expect(phone_number).not_to be_valid
        expect(phone_number.errors[:label]).to include("ist kein gültiger Wert")
      end

      it "validates uniqueness of label scoped to contactable_type and contactable_id" do
        _existing_phone_number = PhoneNumber.create!(
          contactable: people(:mitglied),
          label: "landline",
          number: "0780000000"
        )

        phone_number.label = "landline"
        expect(phone_number).not_to be_valid
        expect(phone_number.errors[:label]).to include("ist bereits vergeben")

        phone_number.label = "mobile"
        expect(phone_number).to be_valid
      end

      it "does not normalize label" do
        I18n.with_locale(:fr) do
          label_translations = I18n.t(PhoneNumber.labels_translations_key)
          expect(label_translations[:mobile]).to eq "Mobile"

          phone_number.label = "mobile"

          expect { phone_number.send(:normalize_label) }.not_to change { phone_number.label }

          phone_number.save!
          expect(phone_number.label).to eq "mobile"
        end
      end
    end
  end
end
