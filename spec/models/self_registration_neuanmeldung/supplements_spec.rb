# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SelfRegistrationNeuanmeldung::Supplements do
  subject(:model) { described_class.new }

  let(:required_attrs) {
    {
      statutes: true,
      contribution_regulations: true,
      data_protection: true,
    }
  }

  describe 'validations' do
    it 'validates aggrements fields' do
      expect(model).not_to be_valid
      expect(model.errors.attribute_names).to match_array [
        :statutes,
        :contribution_regulations,
        :data_protection,
      ]
    end

    it 'is valid if required attrs are set' do
      model.attributes = required_attrs
      expect(model).to be_valid
    end

    context 'sektion statuten are set on group' do
      let(:group) { double(:group, privacy_policy: double(:blob,  attached?: true)) }
      subject(:model) { described_class.new(required_attrs, group) }

      it 'is invalid if privacy_policy_acceptance is not set' do
        expect(model).not_to be_valid
        expect(model.errors.attribute_names).to match_array [:sektion_statuten]
      end

      it 'is valid if privacy_policy_acceptance is set' do
        model.attributes = required_attrs.merge(sektion_statuten: true)
        expect(model).to be_valid
      end
    end
  end
end
