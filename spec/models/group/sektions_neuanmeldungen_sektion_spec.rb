# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Group::SektionsNeuanmeldungenSektion do
  describe Group::SektionsNeuanmeldungenSektion::Neuanmeldung do
    let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
    let(:person) { people(:admin) }
    subject(:role) { Fabricate(described_class.sti_name, person: person, group: group, created_at: 10.days.ago) }

    it "#destroy hard destroys role even though it is old enough to archive" do
      expect(role.send(:old_enough_to_archive?)).to eq true
      expect { role.destroy }.to change { Role.with_deleted.count }.by(-1)
    end
  end
end
