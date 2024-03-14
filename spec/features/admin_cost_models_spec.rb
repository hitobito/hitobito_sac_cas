# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe 'code models', js: true do
  let(:admin) { people(:admin) }
  before { sign_in(admin) }

  ['Kostenstellen', 'Kostenträger'].each do |model_name|
    it "can create edit and destroy #{model_name}" do
      sign_in(admin)
      visit root_path
      click_on 'Einstellungen'
      click_on model_name
      click_on 'Erstellen'
      fill_in 'Code', with: 'code'
      fill_in 'Bezeichnung', with: 'dummy'
      click_on 'Speichern'
      expect(page).to have_css('.alert-success', text: "code - dummy wurde erfolgreich erstellt.")

      click_on 'Bearbeiten'
      fill_in 'Bezeichnung', with: 'update'
      click_on 'Speichern'
      expect(page).to have_css('.alert-success', text: "code - update wurde erfolgreich aktualisiert.")

      click_on 'Löschen'
      accept_alert
      expect(page).to have_css('.alert-success', text: "code - update wurde erfolgreich gelöscht.")
    end
  end
end
