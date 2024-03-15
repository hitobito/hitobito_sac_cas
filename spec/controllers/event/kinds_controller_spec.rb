# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Event::KindsController do
  before { sign_in(people(:admin)) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  it 'permits additional attributes' do
    expect(described_class.permitted_attrs).to include(
      :cost_center_id,
      :cost_unit_id,
      :maximum_participants,
      :minimum_participants,
      :training_days,
      :season,
      :reserve_accommodation,
      :accomodation
    )
  end

  it 'POST#create creates new event_kind' do
    expect do
      post :create, params: {
        event_kind: {
          short_name: 'Skitour',
          label: 'Skitour',
          kind_category_id: event_kind_categories(:ski_course).id,
          level_id: event_levels(:ek).id,
          cost_center_id: cost_centers(:tour).id,
          cost_unit_id: cost_units(:ski).id
        }
      }
    end.to change { Event::Kind.count }.by(1)
  end
end
