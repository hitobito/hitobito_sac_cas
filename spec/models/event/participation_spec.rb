# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::Participation do

  describe '::callbacks' do
    subject(:participation) { Fabricate(:event_participation, event: events(:top_course)) }

    [
      {state: :canceled, canceled_at: Time.zone.today},
      {state: :annulled}
    ].each do |attrs|
      it "sets previous state when updating to #{attrs[:state]}" do
        expect do
          participation.update!(attrs)
        end.to change { participation.reload.previous_state }.from(nil).to('assigned')
      end
    end
  end
end
