# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Event::ParticipationsController do
  before { sign_in(people(:admin)) }
  context 'state changes' do
    let(:group) { course.groups.first }
    let(:course) { events(:top_course) }
    let(:participation) { Fabricate(:event_participation, event: course) }

    it 'PUT summon sets participation state to abset' do
      put :summon,
        params: {
          group_id: group.id,
          event_id: course.id,
          id: participation.id
        }
      participation.reload
      expect(participation.active).to be false
      expect(participation.state).to eq 'summoned'
      expect(flash[:notice]).to match /wurde aufgeboten/
    end
  end
end

