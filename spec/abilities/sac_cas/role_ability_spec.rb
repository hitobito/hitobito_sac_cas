# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe RoleAbility do

  let(:person) { people(:mitglied) }
  let(:role_stammsektion) { roles(:mitglied) }
  let(:role_zusatzsektion) { roles(:mitglied_zweitsektion) }

  subject(:ability) { Ability.new(person) }

  def set_termination_by_section_only(role, value)
    role.group.parent.update!(mitglied_termination_by_section_only: value)
  end

  context 'terminating own role' do
    context 'Stammsektion' do
      it 'is permitted when not Sektion#mitglied_termination_by_section_only' do
        set_termination_by_section_only(role_stammsektion, false)
        expect(ability).to be_able_to(:terminate, role_stammsektion)
      end

      it 'is denied when Sektion#mitglied_termination_by_section_only' do
        set_termination_by_section_only(role_stammsektion, true)
        expect(ability).not_to be_able_to(:terminate, role_stammsektion)
      end

      it 'is denied when having Zusatzsektion with Sektion#mitglied_termination_by_section_only' do
        set_termination_by_section_only(role_stammsektion, false)
        set_termination_by_section_only(role_zusatzsektion, true)
        expect(ability).not_to be_able_to(:terminate, role_stammsektion)
      end
    end

    context 'Zusatzsektion' do
      it 'is permitted when not Sektion#mitglied_termination_by_section_only' do
        set_termination_by_section_only(role_zusatzsektion, false)
        expect(ability).to be_able_to(:terminate, role_zusatzsektion)
      end

      it 'is denied when Sektion#mitglied_termination_by_section_only' do
        set_termination_by_section_only(role_zusatzsektion, true)
        expect(ability).not_to be_able_to(:terminate, role_zusatzsektion)
      end

      it 'is permitted when having Hauptsektion with Sektion#mitglied_termination_by_section_only' do
        set_termination_by_section_only(role_stammsektion, true)
        set_termination_by_section_only(role_zusatzsektion, false)
        expect(ability).to be_able_to(:terminate, role_zusatzsektion)
      end
    end
  end

end
