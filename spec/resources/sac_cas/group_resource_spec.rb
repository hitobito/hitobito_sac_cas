# frozen_string_literal: true
#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require 'spec_helper'

describe GroupResource, type: :resource do
  include Rails.application.routes.url_helpers

  let(:person) { people(:admin) }
  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:geschaeftsstelle) { groups(:geschaeftsstelle) }

  it 'includes navision id' do
    params[:filter] = { id: { eq: bluemlisalp.id } }
    render
    expect(jsonapi_data[0].attributes['navision_id']).to eq 1650
  end

  it 'includes foundation year and section canton as extra attribute' do
    bluemlisalp.update!(created_at: 1.day.ago, foundation_year: 1900, section_canton: 'BE')
    params[:filter] = { id: { eq: bluemlisalp.id } }
    params[:extra_fields] = { groups: 'foundation_year,section_canton' }
    render
    expect(jsonapi_data[0].attributes['foundation_year']).to eq '1900'
    expect(jsonapi_data[0].attributes['section_canton']).to eq 'BE'
  end

  it 'returns blank values if group does not have underlying mounted attributes' do
    params[:filter] = { id: { eq: geschaeftsstelle.id } }
    params[:extra_fields] = { groups: 'foundation_year,section_canton' }
    render
    expect(jsonapi_data[0].attributes['foundation_year']).to be_blank
    expect(jsonapi_data[0].attributes['section_canton']).to be_blank
  end
end
