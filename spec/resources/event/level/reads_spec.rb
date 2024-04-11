# frozen_string_literal: true
#
# Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require 'spec_helper'

describe Event::LevelResource, type: :resource do
  let(:person) { people(:admin) }
  let(:serialized_attrs) do
    [
      :label,
      :code,
      :difficulty,
    ]
  end

  it 'includes additional attributes' do
    render
    data = jsonapi_data[0]
    expect(data.attributes.symbolize_keys.keys).to match_array [:id,
                                                                :jsonapi_type] + serialized_attrs

  end
end
