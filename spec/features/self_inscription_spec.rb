# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe :self_inscription, js: true do

  subject { page }

  let(:mitglied) { people(:mitglied) }
  let(:mitglieder) { groups(:bluemlisalp_mitglieder) }
  let(:geschaeftsstelle) { groups(:geschaeftsstelle) }

  let(:admin) { people(:admin) }
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:other_group) { groups(:matterhorn_neuanmeldungen_sektion) }

  before do
    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
  end

  it 'redirects if person is already a member of that group' do
    mitglieder.update!(self_registration_role_type: Group::SektionsMitglieder::Mitglied.sti_name)

    sign_in(mitglied)
    visit group_self_inscription_path(group_id: mitglieder)
    expect(page).to have_css('#flash .alert-danger', text: 'Du bist bereits Mitglied dieser Sektion')
  end

  it 'has standard behaviour ' do
    geschaeftsstelle.update!(self_registration_role_type: Group::Geschaeftsstelle::Fundraising)
    sign_in(mitglied)
    visit group_self_inscription_path(group_id: geschaeftsstelle)
    click_link 'Beitreten'
    expect(page).to have_css("#flash", text: 'Die Rolle wurde erfolgreich gespeichert')
  end

  describe 'sektion neuanmeldungen' do
    describe 'form' do
      it 'has custom sac_cas content' do
        sign_in(admin)
        visit group_self_inscription_path(group_id: group)
        expect(page).to have_selector('h1', text: 'Registrierung zu SAC Blüemlisalp')
        expect(page).to have_selector('.details', text: 'Du trittst mit Beitragskategorie Einzel bei.')
        expect(page).to have_button 'Beitreten'
      end
    end

    describe 'modal dialog' do
      context 'simple' do
        before do
          sign_in(admin)
          visit group_self_inscription_path(group_id: group)
          choose 'Sofort'
          choose 'Neue Stammsektion'
          click_button 'Beitreten'
          expect(page).to have_selector('#confirm-dialog.modal')
        end

        it 'can cancel triggers request, there doesnt keep state' do
          click_link 'Abbrechen'
          expect(page).not_to have_selector('#confirm-dialog.modal')
          expect(page).to have_checked_field 'Sofort'
        end

        it 'creates role' do
          click_button 'Beitritt beantragen'
          expect(page).to have_css("#flash", text: 'Die Rolle wurde erfolgreich gespeichert')
          expect(page).to have_css('section:nth-of-type(2)', text: 'SAC Blüemlisalp / Neuanmeldungen (zur Freigabe)')
          expect(page).not_to have_css('section:nth-of-type(3)', text: 'SAC Blüemlisalp / Neuanmeldungen (zur Freigabe)')
        end
      end

      context 'with variable date' do
        around { |example| travel_to(Time.now.beginning_of_year) { example.run } }

        before do
          sign_in(admin)
          visit group_self_inscription_path(group_id: group)
          choose 'Neue Stammsektion'
        end

        it 'can create future role from Juli onwards' do
          choose '01. Juli'
          click_button 'Beitreten'
          expect(page).to have_css('#confirm-dialog')

          click_button 'Beitritt beantragen'
          expect(page).to have_css("#flash", text: 'Die Rolle wurde erfolgreich gespeichert')
          expect(page).not_to have_css('section:nth-of-type(2)', text: 'SAC Blüemlisalp / Neuanmeldungen (zur Freigabe)')
          expect(page).to have_css('section:nth-of-type(3)', text: "SAC Blüemlisalp / Neuanmeldungen (zur Freigabe)\nNeuanmeldung (ab 01.07.2023)")
        end
      end
    end
  end
end
