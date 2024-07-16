# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Memberships::JoinZusatzsektion do
  let(:matterhorn) { groups(:matterhorn) }
  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:backoffice) { true }
  let(:params) { {} }
  let!(:person) do
    Fabricate(Group::Sektion::SektionsMitglieder::Mitglied.sti_name,
      group: groups(:bluemlisalp_mitglieder)).person
  end

  let(:wizard) do
    described_class.new(current_step: @current_step.to_i, backoffice: backoffice, person: person,
                        **params)
  end

  context "person outside of a household" do
    it "has ChooseSektion and Summary steps" do
      expect(wizard.step_at(0)).to be_kind_of(Wizards::Steps::ChooseSektion)
      expect(wizard.step_at(1)).to be_kind_of(Wizards::Steps::JoinZusatzsektion::Summary)
    end

    it "only has MembershipTerminatedInfo step if role is terminated" do
      person.roles.first.update_column(:terminated, true)
      expect(wizard.step_at(0)).to be_kind_of(Wizards::Steps::MembershipTerminatedInfo)
      expect(wizard.step_at(1)).to be_nil
    end

    context "validations" do
      it "validates group but does not copy error" do
        params["choose_sektion"] = {group_id: groups(:root).id}
        expect(wizard).not_to be_valid
        expect(wizard.step_at(0).errors.full_messages).to eq [
          "Sektion wählen ist nicht gültig"
        ]
        expect(wizard.errors.full_messages).to be_empty
      end

      context "valid group" do
        before do
          params["choose_sektion"] = {group_id: matterhorn.id}
        end

        it "is valid" do
          expect(wizard).to be_valid
        end

        context "no self service and not backoffice" do
          let(:backoffice) { false }

          it "is still valid even if sektion does not support self service" do
            expect(wizard).to be_valid
          end
        end
      end

      describe "JoinOperation" do
        before do
          @current_step = 1
          params["choose_sektion"] = {group_id: matterhorn.id}
          expect(wizard).to be_last_step
        end

        it "is valid" do
          expect(wizard).to be_valid
          expect(wizard.errors.full_messages).to be_empty
        end

        it "copies errors when invalid" do
          person.roles.destroy_all
          expect(wizard).not_to be_valid
          expect(wizard.errors.full_messages).to eq ["Person muss Sac Mitglied sein"]
        end

        it "does not fail when valid is called twice" do
          person.roles.destroy_all
          2.times { wizard.valid? }
          expect(wizard.errors.full_messages).to eq ["Person muss Sac Mitglied sein"]
        end
      end
    end

    context "persisting" do
      before do
        @current_step = 1
        params["choose_sektion"] = {group_id: matterhorn.id}
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
        params["choose_sektion"] = {group_id: matterhorn.id}
        roles(:familienmitglied_zweitsektion).destroy
      end

      it "may create single role" do
        params["choose_membership"] = {register_as: :myself}
        expect(wizard).to be_last_step
        expect(wizard).to be_valid
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

  describe "#human_role_type" do
    let(:person) { people(:mitglied) }
    let(:params) { {"choose_sektion" => {group_id: matterhorn.id}} }

    before do
      wizard.step_at(0) # trigger build_step_instances
    end

    it "is Einzelmitglied" do
      expect(wizard.human_role_type).to eq "Einzelmitglied"
    end

    it "is Jungedmitglied when person is young enough" do
      person.update(birthday: 20.years.ago)
      expect(wizard.human_role_type).to eq "Jugendmitglied"
    end

    context "family" do
      let(:person) { people(:familienmitglied) }

      it "is Einzelmitglied" do
        expect(wizard.human_role_type).to eq "Einzelmitglied"
      end

      context "when register_as is set accordingly" do
        let(:params) do
          {
            "choose_sektion" => {group_id: matterhorn.id},
            "choose_membership" => {register_as: :family}
          }
        end

        it "is Familienmitglied if register_as is set accordingly" do
          expect(wizard.human_role_type).to eq "Familienmitglied"
        end
      end
    end
  end
end
