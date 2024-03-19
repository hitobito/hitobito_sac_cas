# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe 'Mailing list edit page', js: true do
  let(:user) { people(:root) }
  let(:mailing_list) { Fabricate(:mailing_list, group: groups(:root)) }
  let(:newsletter) do
    MailingListSeeder.seed!
    MailingList.find_by(internal_key: SacCas::NEWSLETTER_MAILING_LIST_INTERNAL_KEY)
  end

  def show_mailing_list(mailing_list)
    visit group_mailing_list_path(group_id: mailing_list.group_id, id: mailing_list.id)
  end

  def edit_mailing_list(mailing_list)
    visit edit_group_mailing_list_path(group_id: mailing_list.group_id, id: mailing_list.id)
  end

  [:root, :admin].each do |person_key|
    context "as #{person_key}" do
      let(:user) { people(person_key) }

      before { sign_in(user) }

      context 'with regular mailing list' do
        it 'can update mailing list subscribable_for and subscribable_mode' do
          edit_mailing_list(mailing_list)
          fill_in 'mailing_list_name', with: 'New label'
          expect(page).to have_selector('input#mailing_list_subscribable_for_configured')
          choose 'Nur konfigurierte Abonnenten'
          expect(page).to have_selector('input#mailing_list_subscribable_mode_opt_out')
          choose 'Angemeldet (opt-out)'

          expect do
            click_button 'Speichern'
            expect(page).to have_selector('#flash .alert-success', text: 'erfolgreich aktualisiert')
          end.to change { mailing_list.reload.name }.to('New label').
            and change { mailing_list.reload.subscribable_for }.to('configured').
            and change { mailing_list.reload.subscribable_mode }.to('opt_out')
        end

        it 'can destroy mailing list' do
          show_mailing_list(mailing_list)
          accept_confirm { click_link 'Löschen' }
          expect(page).to have_selector('#flash .alert-success', text: 'erfolgreich gelöscht')
          expect { mailing_list.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with newsletter mailing list' do
        it 'can update mailing list' do
          edit_mailing_list(newsletter)
          fill_in 'mailing_list_name', with: 'New label'

          expect do
            click_button 'Speichern'
            expect(page).to have_selector('#flash .alert-success', text: 'erfolgreich aktualisiert')
          end.to change { newsletter.reload.name }.to('New label')
        end

        it 'cannot update mailing list subscribable_for and subscribable_mode' do
          edit_mailing_list(newsletter)

          expect(page).to have_no_selector('input#mailing_list_subscribable_for_configured')
          expect(page).to have_no_selector('input#mailing_list_subscribable_mode_opt_out')
        end

        it 'cannot destroy newsletter mailing list' do
          show_mailing_list(newsletter)
          expect(page).to have_no_link 'Löschen'
        end
      end
    end
  end

end
