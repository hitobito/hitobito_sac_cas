# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe RoleAbility do
  let(:person) { people(:mitglied) }
  let(:role_stammsektion) { roles(:mitglied) }
  let(:role_zusatzsektion) { roles(:mitglied_zweitsektion) }

  subject(:ability) { Ability.new(person) }

  def set_termination_by_section_only(role, value)
    role.group.parent.update!(mitglied_termination_by_section_only: value)
  end

  context "terminating own role" do
    context "Stammsektion" do
      it "is permitted when not Sektion#mitglied_termination_by_section_only" do
        set_termination_by_section_only(role_stammsektion, false)
        expect(ability).to be_able_to(:terminate, role_stammsektion)
      end

      it "is denied when Sektion#mitglied_termination_by_section_only" do
        set_termination_by_section_only(role_stammsektion, true)
        expect(ability).not_to be_able_to(:terminate, role_stammsektion)
      end

      it "is denied when having Zusatzsektion with Sektion#mitglied_termination_by_section_only" do
        set_termination_by_section_only(role_stammsektion, false)
        set_termination_by_section_only(role_zusatzsektion, true)
        expect(ability).not_to be_able_to(:terminate, role_stammsektion)
      end
    end

    context "Zusatzsektion" do
      it "is permitted when not Sektion#mitglied_termination_by_section_only" do
        set_termination_by_section_only(role_zusatzsektion, false)
        expect(ability).to be_able_to(:terminate, role_zusatzsektion)
      end

      it "is denied when Sektion#mitglied_termination_by_section_only" do
        set_termination_by_section_only(role_zusatzsektion, true)
        expect(ability).not_to be_able_to(:terminate, role_zusatzsektion)
      end

      it "is permitted when having Stammsektion with Sektion#mitglied_termination_by_section_only" do
        set_termination_by_section_only(role_stammsektion, true)
        set_termination_by_section_only(role_zusatzsektion, false)
        expect(ability).to be_able_to(:terminate, role_zusatzsektion)
      end
    end

    context "Abo" do
      let(:person) { people(:abonnent) }
      let(:role_abonnent) { roles(:abonnent_alpen) }

      it "is denied when Sektion#mitglied_termination_by_section_only" do
        expect(ability).not_to be_able_to(:terminate, role_abonnent)
      end
    end
  end

  context "managing admin roles" do
    let(:admin_role) { Fabricate(Group::Geschaeftsstelle::Admin.name.to_sym, group: groups(:geschaeftsstelle)) }

    context "as admin" do
      let(:person) { people(:admin) }

      it "is able to create role with admin permission" do
        expect(ability).to be_able_to(:create, admin_role)
      end

      it "is able to update role with admin permission" do
        expect(ability).to be_able_to(:update, admin_role)
      end

      it "is able to destroy role with admin permission" do
        expect(ability).to be_able_to(:destroy, admin_role)
      end
    end

    context "as non admin" do
      let(:person) do
        role = Fabricate(Group::Geschaeftsstelle::Mitarbeiter.name.to_sym, group: groups(:geschaeftsstelle), person: people(:mitglied))
        role.person
      end

      it "is able to create role without admin permission" do
        expect(ability).to be_able_to(:create, roles(:mitglied))
      end

      it "is not able to create role with admin permission" do
        expect(ability).not_to be_able_to(:create, admin_role)
      end

      it "is able to update role without admin permission" do
        expect(ability).to be_able_to(:update, roles(:mitglied))
      end

      it "is not able to update role with admin permission" do
        expect(ability).not_to be_able_to(:update, admin_role)
      end

      it "is able to destroy role without admin permission" do
        expect(ability).to be_able_to(:destroy, roles(:tourenchef_bluemlisalp_ortsgruppe_ausserberg))
      end

      it "is not able to destroy role with admin permission" do
        expect(ability).not_to be_able_to(:destroy, admin_role)
      end
    end
  end

  describe "wizard managed roles" do
    {
      bluemslisap_mitglieder: [
        ::Group::SektionsMitglieder::Mitglied,
        ::Group::SektionsMitglieder::MitgliedZusatzsektion
      ],
      bluemlisalp_neuanmeldungen_nv: [
        ::Group::SektionsNeuanmeldungenNv::Neuanmeldung,
        ::Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion
      ],
      bluemlisalp_neuanmeldungen_sektion: [
        ::Group::SektionsNeuanmeldungenSektion::Neuanmeldung,
        ::Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion
      ],
      abo_magazine: [
        ::Group::AboMagazin::Abonnent,
        ::Group::AboMagazin::Neuanmeldung
      ],
      abo_touren_portal: [
        ::Group::AboTourenPortal::Abonnent,
        ::Group::AboTourenPortal::Neuanmeldung
      ]
    }.each do |group_key, role_types|
      let(:group) do
        if group_key == :abo_touren_portal
          Fabricate(Group::AboTourenPortal.sti_name, parent: groups(:abos))
        else
          groups(group_key)
        end
      end

      role_types.each do |role_type|
        let(:role) { Fabricate(role_type.sti_name, group: group) }

        it "cannot destroy #{role_type}" do
          expect(ability).not_to be_able_to(:destroy, role)
        end
      end
    end
  end
end
