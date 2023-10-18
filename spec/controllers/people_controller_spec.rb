# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe PeopleController do

  render_views

  let(:body) { Capybara::Node::Simple.new(response.body) }
  let(:admin) { people(:admin) }

  let(:people_table) { body.all('#main table tbody tr') }
  let(:pagination_info) { body.find('.pagination-info').text.strip }
  let(:members_filter) { body.find('.toolbar-pills > ul > li:nth-child(1)') }
  let(:custom_filter) { body.find('.toolbar-pills > ul > li.dropdown') }

  before { sign_in(admin) }

  it 'GET#index accepts filter params and lists neuanmeldungen' do
    person1 = Fabricate(:person, birthday: Time.zone.today - 42.years)
    Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.to_s,
              group: groups(:bluemlisalp_neuanmeldungen_nv),
              person: person1)
    person2 = Fabricate(:person, birthday: Time.zone.today - 42.years)
    Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.to_s,
              group: groups(:bluemlisalp_neuanmeldungen_sektion),
              person: person2)
    roles = { role_type_ids: Group::SektionsNeuanmeldungenNv::Neuanmeldung.id }
    get :index, params: { group_id: groups(:root).id, filters: { role: roles }, range: 'deep' }

    expect(custom_filter[:class]).to eq 'dropdown active'
    expect(members_filter.text).to eq 'Neuanmeldungen (1)'
    expect(members_filter[:class]).not_to eq 'active'

    expect(pagination_info).to eq '1 Person angezeigt.'
    expect(people_table).to have(1).item

  end
end
