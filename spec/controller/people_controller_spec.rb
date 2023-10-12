# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe PeopleController do

  render_views

  let(:body)      { Capybara::Node::Simple.new(response.body) }
  let(:sekretaer) { people(:sekretaer) }

  let(:people_table) { body.all('#main table tbody tr') }
  let(:pagination_info) { body.find('.pagination-info').text.strip }
  let(:members_filter) { body.find('.toolbar-pills > ul > li:nth-child(1)') }
  let(:custom_filter) { body.find('.toolbar-pills > ul > li.dropdown') }

  before { sign_in(sekretaer) }

  it 'GET#index lists both members on top layer' do
    get :index, params: { group_id: groups(:root).id }
    expect(members_filter.text).to eq 'Mitglieder (2)'
    expect(members_filter[:class]).to eq 'active'
    expect(custom_filter[:class]).not_to eq 'active'

    expect(pagination_info).to eq '2 Personen angezeigt.'
    expect(people_table).to have(2).item
  end

  it 'GET#index accepts filter params and lists only single megmber' do
    roles = { role_type_ids: Group::SektionsMitglieder::Einzel.id }
    get :index, params: { group_id: groups(:root).id, filters: { role: roles }, range: 'deep' }

    expect(custom_filter[:class]).to eq 'dropdown active'
    expect(members_filter.text).to eq 'Mitglieder (2)'
    expect(members_filter[:class]).not_to eq 'active'

    expect(pagination_info).to eq '1 Person angezeigt.'
    expect(people_table).to have(1).item

  end

  it 'GET#index lists single member for kanton bern  on top layer' do
    get :index, params: { group_id: groups(:be).id }
    expect(members_filter.text).to eq 'Mitglieder (1)'
    expect(pagination_info).to eq '1 Person angezeigt.'
    expect(people_table).to have(1).item
  end

  it 'GET#index lists single member on Mitglieder group' do
    get :index, params: { group_id: groups(:be_thun_mitglieder).id }
    expect(members_filter.text).to eq 'Mitglieder (1)'
    expect(pagination_info).to eq '1 Person angezeigt.'
    expect(people_table).to have(1).item
  end

end
