#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe 'people/_details_sac_cas.html.haml' do
  include FormatHelper

  let(:dom) { render; Capybara::Node::Simple.new(@rendered)  }

  before do
    allow(view).to receive_messages(current_user: person)
    allow(view).to receive_messages(entry: PersonDecorator.decorate(person))
    allow(controller).to receive_messages(current_user: Person.new)
  end

  context 'member' do
    let(:person) { Person.with_membership_years.find(people(:mitglied).id) }

    it 'renders membership info for active membership' do
      expect(dom).to have_css 'dl dt', text: 'Anzahl Mitglieder-Jahre'
      expect(dom).to have_css 'dl dt', text: 'Mitglied-Nr'
    end

    it 'renders membership info for past membership' do
      person.roles.destroy_all
      expect(dom).to have_css 'dl dt', text: 'Anzahl Mitglieder-Jahre'
      expect(dom).to have_css 'dl dt', text: 'Mitglied-Nr'
    end

    it 'renders membership info for future membership' do
      person.roles.destroy_all
      person.roles.create!(
        type: FutureRole.sti_name,
        group: groups(:bluemlisalp_mitglieder),
        convert_on: 1.month.from_now,
        convert_to: Group::SektionsMitglieder::Mitglied.sti_name
      )
      expect(dom).to have_css 'dl dt', text: 'Anzahl Mitglieder-Jahre'
      expect(dom).to have_css 'dl dt', text: 'Mitglied-Nr'
    end
  end

  context 'other' do
    let(:person) { people(:admin) }

    it 'hides membership info' do
      expect(dom).not_to have_css 'dl dt', text: 'Anzahl Mitglieder-Jahre'
      expect(dom).not_to have_css 'dl dt', text: 'Mitglied-Nr'
    end
  end
end
