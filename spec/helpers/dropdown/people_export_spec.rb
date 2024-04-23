# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Dropdown::PeopleExport do
  include Rails.application.routes.url_helpers
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:user) { people(:admin) }
  let(:dropdown) do
    Dropdown::PeopleExport.new(
      self,
      user,
      { controller: 'people', group_id: groups(:bluemlisalp_mitglieder).id }
    )
  end

  subject { Capybara.string(dropdown.to_s) }

  def menu = subject.find('.btn-group > ul.dropdown-menu')
  def top_menu_entries = menu.all('> li > a').map(&:text)

  def submenu_entries(name)
    menu.all("> li > a:contains('#{name}') ~ ul > li > a").map(&:text)
  end

  it 'renders dropdown' do
    is_expected.to have_content 'Export'

    expect(top_menu_entries).to match_array %w(CSV Excel vCard PDF)
    expect(submenu_entries('CSV')).to match_array %w(Spaltenauswahl Adressliste Empfänger)
  end
end
