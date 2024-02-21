# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistration::MainPerson do
  subject(:model) { described_class.new }
  let(:group) { groups(:geschaeftsstelle) }
  let(:required_attrs) { { first_name: 'test', last_name: 'dummy' } }

  context 'with group requiring adult consent' do
    before do
      group.update!(
        self_registration_require_adult_consent: true,
        self_registration_role_type: group.role_types.first
      )
      model.primary_group = group
      model.attributes = required_attrs
    end

    it 'is valid when adult consent is not explicitly denied' do
      expect(model).to be_valid
    end

    it 'is valid when adult consent is explicitly set' do
      model.adult_consent = '1'
      expect(model).to be_valid
    end

    it 'is invalid when adult consent is explicitly denied' do
      model.adult_consent = '0'
      expect(model).not_to be_valid
      expect(model).to have(1).error_on(:adult_consent)
    end
  end
end
