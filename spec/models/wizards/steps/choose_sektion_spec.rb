# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::ChooseSektion do
  let(:wizard) { Wizards::Base.new(current_step: 0) }

  subject(:step) { described_class.new(wizard) }

  let(:group) { groups(:bluemlisalp) }

  describe "validations" do
    it "validates presence of group id" do
      step.group_id = nil
      expect(step).not_to be_valid
      expect(step.errors[:group_id]).to eq ["muss ausgefüllt werden"]
    end

    it "validates type of group id" do
      step.group_id = Group::SacCas.first.id
      expect(step).not_to be_valid
      expect(step.errors[:group_id]).to eq ["ist nicht gültig"]
    end

    context "self service" do
      before { step.group_id = group.id }

      it "is invalid when triggered by normal user" do
        allow(wizard).to receive(:backoffice?).and_return(false)
        expect(step).not_to be_valid
        expect(step.errors[:base]).to eq [
          "Wir bitten dich den gewünschten Sektionswechsel telefonisch oder per " \
          "E-Mail* zu beantragen. Nimm dazu bitte Kontakt mit uns auf"
        ]
      end

      it "is valid when triggered by backoffice user" do
        allow(wizard).to receive(:backoffice?).and_return(true)
        expect(step).to be_valid
      end

      it "is valid when triggered by normal user but self service is allowed" do
        allow(wizard).to receive(:backoffice?).and_return(false)
        Group::SektionsNeuanmeldungenSektion.destroy_all
        expect(step).not_to be_valid
      end
    end
  end
end
