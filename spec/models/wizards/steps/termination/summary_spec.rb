# frozen_string_literal: true

#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::Termination::Summary do
  let(:params) { {} }
  let(:wizard) { nil } # we don't need a wizard for the model specs
  let(:subject) { described_class.new(wizard, **params) }

  context "without termination_reason_id" do
    it "is invalid" do
      is_expected.not_to be_valid
      expect(subject.errors[:termination_reason_id]).to include("muss ausgefüllt werden")
    end
  end

  context "with termination_reason" do
    let(:params) { {termination_reason_id: termination_reasons(:moved).id} }

    it { is_expected.to be_valid }
  end

  context "with additional params" do
    let(:params) {
      {
        termination_reason_id: termination_reasons(:moved).id,
        data_retention_consent: true,
        subscribe_newsletter: true,
        subscribe_fundraising_list: true
      }
    }

    it { is_expected.to be_valid }
  end

  describe "#family_member_names" do
    let(:person) { people(:familienmitglied) }
    let(:wizard) { Wizards::Base.new(current_step: 0) }

    before do
      allow(wizard).to receive(:person).and_return(person)
    end

    it "returns the family member names" do
      expect(subject.family_member_names).to eq("Tenzing Norgay, Frieda Norgay und Nima Norgay")
    end
  end
end
