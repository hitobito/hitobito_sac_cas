# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Memberships::SwitchStammsektion do
  let(:backoffice) { false }
  let(:matterhorn) { groups(:matterhorn) }
  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:params) { {} }
  let(:stammsektion_role) { person.sac_membership.stammsektion_role }
  let(:email) {
    Delayed::Job.last.payload_object.perform
    ActionMailer::Base.deliveries.first
  }

  let(:wizard) do
    described_class.new(current_step: @current_step.to_i, backoffice:, person:, **params)
  end

  context "single person" do
    let(:person) { people(:mitglied) }

    it "has two steps" do
      expect(wizard.step_at(0)).to be_kind_of(Wizards::Steps::ChooseSektion)
      expect(wizard.step_at(0)).to be_instance_of(Wizards::Steps::SwitchStammsektion::ChooseSektion)
      expect(wizard.step_at(1)).to be_instance_of(Wizards::Steps::SwitchStammsektion::Summary)
    end

    it "has only MembershipTerminatedInfo step if stammsektion_role is terminated" do
      stammsektion_role.update_column(:terminated, true)
      expect(wizard.step_at(0)).to be_instance_of(Wizards::Steps::MembershipTerminatedInfo)
      expect(wizard.step_at(1)).to be_nil
    end

    describe "persisting" do
      let(:backoffice) { true }

      before do
        @current_step = 1
        params["choose_sektion"] = {group_id: matterhorn.id}
        expect(wizard).to be_last_step
        roles(:mitglied_zweitsektion).destroy
      end

      it "switches stammsektion and sends email", :dj_queue do
        expect(wizard).to be_last_step
        expect { expect(wizard.save!).to eq true }
          .to change { person.sac_membership.stammsektion_role.group.parent.name }
          .from("SAC Blüemlisalp").to("SAC Matterhorn")
          .and not_change { Role.count }

        expect(email.subject).to eq("Bestätigung Sektionswechsel")
        expect(email.body).to match(/Hallo Edmund Hillary/)
        expect(email.body).to match(/Sektionswechsel zu SAC Matterhorn wurde/)
      end
    end
  end

  context "household" do
    let(:familienmitglied2) { people(:familienmitglied2) }

    context "for main person" do
      let(:person) { people(:familienmitglied) }

      it "has two steps" do
        # rubocop:todo Layout/LineLength
        expect(wizard.step_at(0)).to be_instance_of(Wizards::Steps::SwitchStammsektion::ChooseSektion)
        # rubocop:enable Layout/LineLength
        expect(wizard.step_at(1)).to be_instance_of(Wizards::Steps::SwitchStammsektion::Summary)
      end

      it "has only MembershipTerminatedInfo step if stammsektion_role is terminated" do
        stammsektion_role.update_column(:terminated, true)
        expect(wizard.step_at(0)).to be_instance_of(Wizards::Steps::MembershipTerminatedInfo)
        expect(wizard.step_at(1)).to be_nil
      end
    end

    context "for other person" do
      let(:person) { familienmitglied2 }

      it "only has the AskFamilyMainPerson step" do
        expect(wizard.step_at(0)).to be_instance_of(Wizards::Steps::AskFamilyMainPerson)
      end

      context "when operator is backoffice" do
        let(:backoffice) { true }

        it "includes the backoffice steps" do
          # rubocop:todo Layout/LineLength
          expect(wizard.step_at(0)).to be_instance_of(Wizards::Steps::SwitchStammsektion::ChooseSektion)
          # rubocop:enable Layout/LineLength
        end
      end
    end

    describe "persisting" do
      let(:backoffice) { true }

      before do
        @current_step = 1
        params["choose_sektion"] = {group_id: matterhorn.id}
        expect(wizard).to be_last_step
        roles(:familienmitglied_zweitsektion).destroy
        roles(:familienmitglied2_zweitsektion).destroy
        roles(:familienmitglied_kind_zweitsektion).destroy
      end

      context "for main person" do
        let(:person) { people(:familienmitglied) }

        it "switches stammsektion and sends email", :dj_queue do
          expect { expect(wizard.save!).to eq true }
            .to change { person.sac_membership.stammsektion_role.group.parent.name }
            .from("SAC Blüemlisalp").to("SAC Matterhorn")
            .and change { familienmitglied2.sac_membership.stammsektion_role.group.parent.name }
            .from("SAC Blüemlisalp").to("SAC Matterhorn")
            .and not_change { Role.count }

          expect(email.subject).to eq("Bestätigung Sektionswechsel")
          expect(email.body).to match(/Hallo Tenzing Norgay/)
          expect(email.body).to match(/Sektionswechsel zu SAC Matterhorn wurde/)
        end
      end
    end
  end
end
