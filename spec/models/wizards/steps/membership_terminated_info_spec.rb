# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Wizards::Steps::MembershipTerminatedInfo do
  let(:wizard) { nil } # no wizard needed
  subject(:step) { described_class.new(wizard) }
  describe 'validations' do
    it { is_expected.not_to be_valid }
  end

  describe '#termination_date' do
    # let(:wizard) { Wizards::Base.new(current_step: 0) }

    it 'returns the termination date of the person' do
      expect(subject.termination_date).not_to be_nil
    end
  end
end
