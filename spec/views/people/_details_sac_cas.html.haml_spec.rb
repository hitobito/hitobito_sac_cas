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

  context 'family member' do
    let(:person) { people(:familienmitglied2)}

    it 'renders family_id' do
      expect(person.family_id).to be_present # check assumption
      label_node = dom.find('dl dt', text: I18n.t('activerecord.attributes.person.family_id'))
      value_node = label_node.find('+dd')
      expect(value_node.text).to eq person.family_id
    end

    describe 'family_main_person' do
      let(:label_node) { dom.find('dl dt', text: I18n.t('activerecord.attributes.person.family_main_person')) }
      subject(:value_node) { label_node.find('+dd') }

      it 'renders unknown if family has no main person' do
        # clear family_main_person for all family members
        Person.where(household_key: person.household_key).update_all(family_main_person: false)

        expect(value_node.text).to eq I18n.t('global.unknown')
      end

      it 'renders true if person is main person' do
        # clear family_main_person for all family members and set it for this person
        Person.where(household_key: person.household_key).update_all(family_main_person: false)
        person.update!(family_main_person: true)

        expect(value_node.text).to eq I18n.t('global.yes')
      end

      it 'renders link to main person if person is not main person' do
        expect(person.sac_family.main_person).to eq people(:familienmitglied) # check assumption

        expect(value_node).to have_link(person.sac_family.main_person.to_s, href: person_path(person.sac_family.main_person))
      end
    end
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

    it 'hides family info' do
      expect(dom).not_to have_css 'dl dt', text: I18n.t('activerecord.attributes.person.family_id')
      expect(dom).not_to have_css 'dl dt', text: I18n.t('activerecord.attributes.person.family_main_person')
    end
  end
end
