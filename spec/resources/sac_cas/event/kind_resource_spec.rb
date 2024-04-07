# frozen_string_literal: true
#
# Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require 'spec_helper'

describe Event::KindResource, type: :resource do
  let(:kind) { event_kinds(:ski_course) }
  let(:person) { people(:admin) }
  let(:additional_attrs) do
    [
      :maximum_participants,
      :minimum_participants,
      :training_days,
      :season,
      :accommodation,
    ]
  end

  it 'includes additional attributes' do
    render
    data = jsonapi_data[0]
    attrs = data.attributes.symbolize_keys
    additional_attrs.each do |attr|
      expect(attrs).to have_key(attr)
    end
  end
end
