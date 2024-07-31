# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::Signup::Sektion::VariousFields do
  let(:wizard) { Wizards::Signup::SektionWizard.new(group: group) }
  subject(:fields) { described_class.new(wizard) }

  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:fields) { described_class.new(wizard) }

  let(:required_attrs) {
    {
      statutes: true,
      contribution_regulations: true,
      data_protection: true
    }
  }

  describe "validations" do
    let(:reason) { Fabricate(:self_registration_reason) }

    it "is valid if required attrs are set" do
      fields.attributes = required_attrs
      expect(fields).to be_valid
    end

    it "validates aggrements fields" do
      expect(fields).not_to be_valid
      expect(fields.errors.attribute_names).to match_array [
        :statutes,
        :contribution_regulations,
        :data_protection
      ]
      expect(fields.errors.full_messages).to match_array [
        "Statuten muss akzeptiert werden",
        "Beitragsreglement muss akzeptiert werden",
        "Datenschutzerklärung muss akzeptiert werden"
      ]
    end

    # "Einverständniserklärung der Erziehungsberechtigten muss akzeptiert werden"

    context "privacy_policy on layer group" do
      before do
        allow(group.layer_group.privacy_policy).to receive(:attached?).and_return(true)
        fields.attributes = required_attrs
      end

      it "is invalid if privacy_policy_acceptance is not set" do
        fields.sektion_statuten = "0"
        expect(fields).not_to be_valid
        expect(fields.errors.attribute_names).to match_array [:sektion_statuten]
        expect(fields.errors.full_messages).to eq ["Sektionsstatuten muss akzeptiert werden"]
      end

      it "is valid if privacy_policy_acceptance is set" do
        fields.sektion_statuten = "1"
        expect(fields).to be_valid
      end
    end

    context "adult_consent on group" do
      before do
        group.self_registration_require_adult_consent = true
        fields.attributes = required_attrs
      end

      it "is valid when adult consent is explicitly set" do
        fields.adult_consent = "1"
        expect(fields).to be_valid
      end

      it "is invalid when adult consent is explicitly denied" do
        fields.adult_consent = "0"
        expect(fields).not_to be_valid
        expect(fields).to have(1).error_on(:adult_consent)
        expect(fields.errors.full_messages).to eq ["Einverständniserklärung der Erziehungsberechtigten muss akzeptiert werden"]
      end
    end

    describe "register_on" do
      it "defaults to now" do
        expect(fields.register_on).to eq "now"
      end

      it "is invalid if blank" do
        fields.register_on = nil
        expect(fields).not_to be_valid
        expect(fields).to have(1).error_on(:register_on)
      end
    end
  end
end
