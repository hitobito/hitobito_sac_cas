# frozen_string_literal: true

#
# Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "spec_helper"

describe Event::CourseResource, type: :resource do
  let(:event) { events(:closed) }
  let(:person) { people(:admin) }
  let(:additional_attrs) do
    [
      :language,
      :accommodation,
      :season,
      :start_point_of_time,
      :minimum_age,

      :brief_description,
      :specialities,
      :similar_tours,
      :program,
      :price_member,
      :price_regular,
      :price_subsidized,
      :price_js_active_member,
      :price_js_active_regular,
      :price_js_passive_member,
      :price_js_passive_regular
    ]
  end

  it "includes additional attributes" do
    render
    data = jsonapi_data[0]
    attrs = data.attributes.symbolize_keys
    additional_attrs.each do |attr|
      expect(attrs).to have_key(attr)
    end
  end
end
