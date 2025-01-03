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

  context "as sektions admin" do
    let(:person) { Fabricate(Group::SektionsFunktionaere::Administration.sti_name, group: groups(:bluemlisalp_funktionaere)).person }
    let(:role_neuanmeldung) { Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name, group: groups(:bluemlisalp_neuanmeldungen_sektion)) }
    let(:role_leserecht) { Fabricate(Group::SektionsMitglieder::Leserecht.sti_name, group: groups(:bluemlisalp_mitglieder)) }

    it "may not destroy for neuanmeldungs mitglied" do
      expect(ability).to_not be_able_to(:destroy, role_neuanmeldung)
    end

    it "may not destroy for wizard managed role" do
      expect(ability).to_not be_able_to(:destroy, role_stammsektion)
    end

    it "may destroy for regular role" do
      expect(ability).to be_able_to(:destroy, role_leserecht)
    end
  end
end
