# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


require 'spec_helper'

describe Group do

  include_examples 'group types'

  describe '#preferred_primary?' do
    it 'is true for SektionsMitglieder type' do
      expect(Fabricate.build(Group::SektionsMitglieder.sti_name)).to be_preferred_primary
      expect(Fabricate.build(Group::Sektion.sti_name)).not_to be_preferred_primary
    end
  end

  describe '#navision_id_padded' do
    it 'pads the navision_id to 8 characters' do
      group = Group.new(navision_id: 123)
      expect(group.navision_id_padded).to eq('00000123')
    end

    it 'returns nil if navision_id is nil' do
      group = Group.new(navision_id: nil)
      expect(group.navision_id_padded).to be_nil
    end
  end

end
