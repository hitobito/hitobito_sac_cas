# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe :self_inscription, js: true do

  subject { page }

  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:user) { people(:mitglied) }

  before do
    user.update!(birthday: 30.years.ago)
    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
    expect(group.self_registration_role_type).to be_present
    expect(user.reload.roles.where(group_id: group.id,
                                   type: group.self_registration_role_type)).not_to exist
  end

  it 'the form has custom sac_cas content' do
    sign_in(user)
    visit group_self_inscription_path(group_id: group)

    expect(page).to have_selector('h1', text: 'Registrierung zu SAC Blüemlisalp')
    expect(page).to have_selector('p', text: 'Willst du dieser Sektion beitreten?')
    expect(page).to have_selector('.details', text: 'Du trittst mit Beitragskategorie Einzel bei.')
    expect(page).to have_selector('a.btn', text: 'Beitreten')
  end

end
