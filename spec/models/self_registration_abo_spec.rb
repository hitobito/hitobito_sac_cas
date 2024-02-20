# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistrationAbo do
  let(:group) do
    groups(:abo_die_alpen).tap { |g| g.update(self_registration_role_type: g.role_types.first) }
  end
  shared_examples 'basic behaviour' do
    let(:params) { {} }

    subject(:registration) { build(params) }


    def build(params)
      nested_params = { self_registration: params }
      described_class.new(group: group, params: nested_params)
    end

    it 'is invalid if issues_from_date is blank' do
      expect(registration).to have(1).error_on(:issues_from_date)
    end

    it 'is valid if issues_from date is set' do
      registration.issues_from_date = Date.today
      expect(registration).to be_valid
    end
  end

  it_behaves_like 'basic behaviour'

  describe SelfRegistrationAboBasic do
    let(:group)  { Fabricate.build(Group::AboBasicLogin.sti_name) }

    it_behaves_like 'basic behaviour' do
      it 'has custom main_person class' do
        expect(registration.main_person).to be_kind_of(SelfRegistrationAboBasic::MainPerson)
      end
    end
  end
end
