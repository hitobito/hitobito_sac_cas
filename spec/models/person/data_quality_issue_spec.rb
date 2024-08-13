# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Person::DataQualityIssue do
  let(:person) { people(:mitglied) }

  describe "validations" do
    context "#attr" do
      it "is valid if it is a person attribute" do
        data_quality = person.data_quality_issues.new(attr: "zip_code", key: "-", severity: "info")
        expect(data_quality.valid?).to eq true
      end

      it "is invalid if it isnt a person attribute" do
        data_quality = person.data_quality_issues.new(attr: "fail", key: "", severity: "ok")
        expect(data_quality.valid?).to eq false
        expect(data_quality.errors[:attr]).to eq ["ist nicht gültig"]
      end
    end

    context "#severity" do
      it "is valid if it is in enum" do
        data_quality = person.data_quality_issues.new(attr: "zip_code", key: "-", severity: "info")
        expect(data_quality.valid?).to eq true
      end

      it "is invalid if it isnt in enum" do
        data_quality = person.data_quality_issues.new(attr: "zip_code", key: "-", severity: "ok")
        expect(data_quality.valid?).to eq false
        expect(data_quality.errors[:severity]).to eq ["muss ausgefüllt werden"]
      end
    end
  end
end
