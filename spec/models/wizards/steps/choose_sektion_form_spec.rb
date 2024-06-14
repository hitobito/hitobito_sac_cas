# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Wizards::Steps::ChooseSektionForm do
  let(:wizard) { Wizards::Base.new(current_step: 0) }
  subject(:step) { described_class.new(wizard) }

  describe 'validations' do
    let(:error) { steps.errors[:group] }

    it 'validates presence of group id' do
      step.group_id = nil
      expect(step).not_to be_valid
      expect(step.errors[:group_id]).to eq ['muss ausgefüllt werden']
    end

    it 'validates type of group id' do
      step.group_id = Group::SacCas.first.id
      expect(step).not_to be_valid
      expect(step.errors[:group_id]).to eq ['ist nicht gültig']
    end
  end
end
