# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe People::Membership::VerifyController do
  let(:person) { people(:mitglied) }
  let(:token) { '123' }

  it 'shows invalid token information' do
    visit "/verify_membership/#{token}"
    expect(page).to have_text 'Ungültiger Verifikationscode'
  end

  context 'with valid token' do
    before { person.update!(membership_verify_token: token) }

    it 'shows invalid membership information' do
      person.roles.destroy_all

      visit "/verify_membership/#{token}"
      expect(page).to have_css('.alert-danger', text: 'Keine gültige Mitgliedschaft')
    end

    it 'shows valid membership information' do
      visit "/verify_membership/#{token}"
      expect(page).to have_text 'Edmund Hillary'
      expect(page).to have_text 'Mitglied (Stammsektion) (Einzel) - SAC Blüemlisalp'
      expect(page).to have_css('.alert-success', text: 'Mitgliedschaft gültig')
    end
  end
end
