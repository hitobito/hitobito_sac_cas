# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Memberships::JoinZusatzsektion do
  let(:params) { {} }
  let(:backoffice) { true }
  let(:wizard) do
    described_class.new(current_step: @current_step.to_i, backoffice: backoffice, person: person,
                        **params)
  end

  context "person outside of a household" do
    let(:person) { people(:mitglied) }

    it "has ChooseSektion and Summary steps" do
      expect(wizard.step_at(0)).to be_kind_of(Wizards::Steps::ChooseSektion)
      expect(wizard.step_at(1)).to be_kind_of(Wizards::Steps::JoinZusatzsektion::Summary)
    end

    it "only has MembershipTerminatedInfo step if role is terminated" do
      roles(:mitglied).update_column(:terminated, true)
      expect(wizard.step_at(0)).to be_kind_of(Wizards::Steps::MembershipTerminatedInfo)
      expect(wizard.step_at(1)).to be_nil
    end

    context "validations" do
      let(:root) { groups(:root) }
      let(:sektion) { groups(:bluemlisalp) }

      describe "Choose Sektion" do
        it "is valid when passing accepatable group_id" do
          params["choose_sektion"] = {group_id: sektion.id}
          expect(wizard).to be_valid
        end

        it "is invalid when passing unaccepatable group_id" do
          params["choose_sektion"] = {group_id: root.id}
          expect(wizard).not_to be_valid
          expect(wizard.step_at(0).errors.full_messages).to eq [
            "Sektion wählen ist nicht gültig"
          ]
        end

        context "when not backofice" do
          let(:backoffice) { false }

          it "is invalid if sektion does not support self service" do
            params["choose_sektion"] = {group_id: sektion.id}
            expect(wizard).not_to be_valid
          end
        end
      end

      describe "JoinOperation" do
        before do
          params["choose_sektion"] = {group_id: groups(:bluemlisalp).id}
        end

        it "ignores invalid sektion when not on last step" do
          expect(wizard).not_to be_last_step
          expect(wizard).to be_valid
          expect(wizard.errors.full_messages).to be_empty
        end

        context "on last step" do
          before { @current_step = 1 }

          it "join operation validates on last step" do
            expect(wizard).to be_last_step
            expect(wizard).not_to be_valid
            expect(wizard.errors.full_messages).to eq ["Person ist bereits Mitglied der Sektion oder hat ein offenes Beitrittsgesuch"]
          end

          it "join operation validates on last step" do
            params["choose_sektion"] = {group_id: groups(:matterhorn).id}
            expect(wizard).to be_last_step
            expect(wizard).to be_valid
            expect(wizard.errors.full_messages).to be_empty
          end
        end
      end
    end

    context "persisting" do
      before do
        @current_step = 1
        params["choose_sektion"] = {group_id: groups(:matterhorn).id}
      end

      it "validates join operation on last step" do
        expect(wizard).to be_last_step
        expect { expect(wizard.save!).to eq true }
          .to change { Role.count }.by(1)
      end
    end
  end

  context "for person inside a household" do
    let(:person) { people(:familienmitglied) }

    it "has ChooseMembership, ChooseSektion and Summary steps" do
      expect(wizard.step_at(0)).to be_kind_of(Wizards::Steps::ChooseMembership)
      expect(wizard.step_at(1)).to be_kind_of(Wizards::Steps::ChooseSektion)
      expect(wizard.step_at(2)).to be_kind_of(Wizards::Steps::JoinZusatzsektion::Summary)
    end

    it "only has MembershipTerminatedInfo step if role is terminated" do
      roles(:familienmitglied).update_column(:terminated, true)
      expect(wizard.step_at(0)).to be_kind_of(Wizards::Steps::MembershipTerminatedInfo)
      expect(wizard.step_at(1)).to be_nil
    end

    context "persisting" do
      before do
        @current_step = 2
        params["choose_sektion"] = {group_id: groups(:matterhorn).id}
      end

      it "may create single role" do
        params["choose_membership"] = {register_as: :myself}
        expect(wizard).to be_last_step
        expect { expect(wizard.save!).to eq true }
          .to change { Role.count }.by(1)
      end

      it "may create roles for family" do
        params["choose_membership"] = {register_as: :family}
        expect(wizard).to be_last_step
        expect { expect(wizard.save!).to eq true }
          .to change { Role.count }.by(3)
      end
    end
  end
end
