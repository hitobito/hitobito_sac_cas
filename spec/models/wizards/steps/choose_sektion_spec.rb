# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::ChooseSektion do
  let(:wizard) do
    instance_double(Wizards::Memberships::JoinZusatzsektion, person: people(:abonnent),
      backoffice?: false)
  end

  subject(:step) { described_class.new(wizard) }

  describe "validations" do
    it "validates presence of group id" do
      step.group_id = nil
      expect(step).not_to be_valid
      expect(step.errors[:group_id]).to eq ["muss ausgefüllt werden"]
    end

    it "validates group type" do
      step.group_id = groups(:root).id
      expect(step).not_to be_valid
      expect(step.errors[:group_id]).to eq ["ist nicht gültig"]
    end

    context "with existing memberships" do
      before { allow(wizard).to receive(:person).and_return(people(:mitglied)) }

      it "validates no mitgliedschaft in group exists" do
        step.group_id = groups(:bluemlisalp).id
        expect(step).not_to be_valid

        expect(step.errors[:group_id]).to eq ["ist nicht gültig"]
      end

      it "validates no zusatzmitgliedschaft in group exists" do
        step.group_id = groups(:matterhorn).id
        expect(step).not_to be_valid
        expect(step.errors[:group_id]).to eq ["ist nicht gültig"]
      end
    end

    context "self service" do
      before do
        step.group_id = groups(:bluemlisalp).id
      end

      it "is invalid when triggered by normal user" do
        allow(wizard).to receive(:backoffice?).and_return(false)
        expect(step).not_to be_valid
        expect(step.errors[:base]).to eq [
          "Wir bitten dich den gewünschten Sektionswechsel telefonisch oder per " \
          "E-Mail* zu beantragen. Nimm dazu bitte Kontakt mit uns auf."
        ]
      end

      it "is valid when triggered by backoffice user" do
        allow(wizard).to receive(:backoffice?).and_return(true)
        expect(step).to be_valid
      end

      it "is valid when triggered by normal user but self service is allowed" do
        Group::SektionsNeuanmeldungenSektion.destroy_all
        expect(step).not_to be_valid
      end
    end
  end
end
