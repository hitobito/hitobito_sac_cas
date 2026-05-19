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

  describe "managed roles" do
    let(:abo_touren_portal) { Fabricate(Group::AboTourenPortal.sti_name, parent: groups(:abos)) }
    let(:matterhorn_mitglied) do
      Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym,
        group: groups(:matterhorn_mitglieder)).person
    end
    let(:backoffice_destroyable_roles) do
      [
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.name.to_sym,
          group: groups(:bluemlisalp_neuanmeldungen_nv)),

        Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.name.to_sym,
          group: groups(:bluemlisalp_neuanmeldungen_nv),
          person: matterhorn_mitglied),
        Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.name.to_sym,
          group: groups(:bluemlisalp_neuanmeldungen_sektion)),

        Fabricate(Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion.name.to_sym,
          group: groups(:bluemlisalp_neuanmeldungen_sektion),
          person: matterhorn_mitglied),

        Fabricate(Group::AboMagazin::Neuanmeldung.name.to_sym, group: groups(:abo_die_alpen))
      ]
    end
    let(:wizard_managed_roles) do
      [
        Fabricate(::Group::SektionsMitglieder::Mitglied.name.to_sym,
          group: groups(:bluemlisalp_mitglieder)),
        Fabricate(::Group::SektionsMitglieder::MitgliedZusatzsektion.name.to_sym,
          group: groups(:bluemlisalp_mitglieder),
          person: matterhorn_mitglied),
        Fabricate(::Group::AboMagazin::Abonnent.name.to_sym,
          group: groups(:abo_die_alpen))
      ]
    end
    let(:api_managed_roles) do
      [
        Fabricate(::Group::AboTourenPortal::Abonnent.name.to_sym,
          group: abo_touren_portal)
      ]
    end
    let(:api_managed_neuanmeldung_roles) do
      [
        Fabricate(Group::AboTourenPortal::Neuanmeldung.name.to_sym,
          group: abo_touren_portal)
      ]
    end

    context "as backoffice" do
      let(:person) do
        Fabricate(Group::Geschaeftsstelle::Admin.name.to_sym,
          group: groups(:geschaeftsstelle)).person
      end

      it "is allowed to destroy neuanmeldungen" do
        (backoffice_destroyable_roles + api_managed_neuanmeldung_roles).each do |to_destroy|
          expect(ability).to be_able_to(:destroy, to_destroy)
        end
      end

      it "cannot destroy mitglied or abonnent roles" do
        (wizard_managed_roles + api_managed_roles).each do |to_destroy|
          expect(ability).not_to be_able_to(:destroy, to_destroy)
        end
      end
    end

    context "as sektions admin" do
      let(:person) do
        Fabricate(Group::SektionsFunktionaere::Administration.name.to_sym,
          group: groups(:bluemlisalp_funktionaere)).person
      end

      it "is not allowed to destroy" do
        (backoffice_destroyable_roles + wizard_managed_roles).each do |to_destroy|
          expect(ability).to_not be_able_to(:destroy, to_destroy)
        end
      end
    end

    context "as top layer service token" do
      let(:service_token) do
        Fabricate(:service_token, layer: groups(:root), permission: :layer_and_below_full, groups: true, people: true)
      end
      let(:ability) { TokenAbility.new(service_token) }

      it "can destroy api managed roles" do
        (api_managed_roles + api_managed_neuanmeldung_roles).each do |to_destroy|
          expect(ability).to be_able_to(:destroy, to_destroy)
        end
      end

      it "cannot destroy wizard managed roles" do
        (backoffice_destroyable_roles + wizard_managed_roles).each do |to_destroy|
          expect(ability).not_to be_able_to(:destroy, to_destroy)
        end
      end
    end
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

      context "when leaving household" do
        let(:person) { people(:familienmitglied2) }
        let(:role_stammsektion) { person.sac_membership.stammsektion_role }

        it "cannot terminate on same day" do
          person.household.remove(person).save!
          expect(ability).not_to be_able_to(:terminate, role_stammsektion)
        end

        it "can terminate on next day" do
          person.household.remove(person).save!
          role_stammsektion = person.sac_membership.stammsektion_role
          travel_to(1.day.from_now) do
            expect(ability).to be_able_to(:terminate, role_stammsektion)
          end
        end
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

      it "is allowed" do
        expect(ability).to be_able_to(:terminate, role_abonnent)
      end
    end
  end

  context "managing admin roles" do
    let(:admin_role) {
      Fabricate(Group::Geschaeftsstelle::Admin.name.to_sym, group: groups(:geschaeftsstelle))
    }

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

      context "when leaving household" do
        let(:person) { people(:familienmitglied2) }
        subject(:ability) { Ability.new(people(:admin)) }

        let(:role_stammsektion) { person.sac_membership.stammsektion_role }

        it "cannot terminate on same day" do
          person.household.remove(person).save!
          expect(ability).not_to be_able_to(:terminate, role_stammsektion)
        end

        it "can terminate on next day" do
          person.household.remove(person).save!
          role_stammsektion = person.sac_membership.stammsektion_role
          travel_to(1.day.from_now) do
            expect(ability).to be_able_to(:terminate, role_stammsektion)
          end
        end
      end
    end

    context "as non admin" do
      let(:person) do
        role = Fabricate(Group::Geschaeftsstelle::Mitarbeiter.name.to_sym,
          group: groups(:geschaeftsstelle), person: people(:mitglied))
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
        expect(ability).to be_able_to(:destroy,
          roles(:tourenchef_bluemlisalp_ortsgruppe_ausserberg))
      end

      it "is not able to destroy role with admin permission" do
        expect(ability).not_to be_able_to(:destroy, admin_role)
      end
    end
  end
end
