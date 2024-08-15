# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Person::DataQualityIssue do
  let(:person) { people(:mitglied) }
  let(:data_quality) do
    person.data_quality_issues.new(attr: "zip_code", key: "ist leer", severity: "warning")
  end

  describe "validations" do
    it "is valid" do
      expect(data_quality.valid?).to eq true
    end

    context "#attr" do
      it "is invalid if it isnt a person attribute" do
        expect do
          data_quality.update!(attr: "not_an_attribute")
        end.to raise_error(ActiveRecord::RecordInvalid, /ist nicht gültig/)
      end
    end

    context "#key" do
      it "is invalid if it isnt unique within a [person_id, attr] scope" do
        person.data_quality_issues.create!(attr: "zip_code", key: "ist leer", severity: "error")
        expect(data_quality.valid?).to eq false
        expect(data_quality.errors[:key]).to eq ["ist bereits vergeben"]
      end
    end

    context "#severity" do
      it "is invalid if it isnt in enum" do
        expect do
          data_quality.update!(severity: "not_a_severity")
        end.to raise_error(ActiveRecord::RecordInvalid, /muss ausgefüllt werden/)
      end
    end

    context "#message" do
      it "shows an error message" do
        expect(data_quality.message).to eq("PLZ ist leer")
      end
    end
  end
end
