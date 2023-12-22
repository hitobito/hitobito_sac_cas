# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe 'people list page' do
  let(:admin) { people(:admin) }
  let(:group) { groups(:bluemlisalp_mitglieder) }

  before do
    sign_in(admin)
    visit group_people_path(group_id: group.id)
  end

  it 'allows showing the membership_years column' do
    click_link('Spalten')
    check('Anzahl Mitglieder-Jahre')
    click_link('Spalten')

    expect(page).to have_css('td[data-attribute-name="membership_years"]', count: 4)
  end
end
