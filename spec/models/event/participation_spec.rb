# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::Participation do

  describe '::callbacks' do
    subject(:participation) { Fabricate(:event_participation, event: events(:top_course)) }

    %w(cancelled annulled).each do |state|
      it "sets previous state when updating to #{state}" do
        expect do
          participation.update!(state: state)
        end.to change { participation.reload.previous_state }.from(nil).to('assigned')
      end
    end
  end
end
