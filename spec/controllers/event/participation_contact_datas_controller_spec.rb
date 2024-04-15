#  copyright (c) 2024, schweizer alpen-club. this file is part of
#  hitobito_sac_cas and licensed under the affero general public license version 3
#  or later. see the copying file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Event::ParticipationContactDatasController  do

  let(:group)      { course.groups.first }
  let(:course)     { events(:top_course) }
  let(:entry)      { assigns(:participation_contact_data) }

  before { sign_in(people(:admin)) }

  context 'GET#edit' do
    render_views
    let(:dom)  { Capybara::Node::Simple.new(response.body) }

    it 'renders form and aside for course' do
      get :edit, params: { group_id: group.id, event_id: course.id,
        event_role: { type: Event::Course::Role::Participant.sti_name } }
      expect(dom).to have_css 'aside.card', count: 2
      expect(dom).to have_css 'main > form'
      expect(dom).not_to have_css '#content > form'
    end

    it 'renders form and and no aside for event' do
      event = Fabricate(:event)
      get :edit, params: { group_id: event.groups.first.id, event_id: event.id,
        event_role: { type: Event::Role::Participant.sti_name } }
      expect(dom).not_to have_css 'aside'
      expect(dom).to have_css '#content > form'
    end
  end

  context 'PATCH#update' do
    let(:person) { people(:admin) }

    it 'stores attributes on person if valid' do
      course.update(required_contact_attrs: %w(phone_numbers))
      number = person.phone_numbers.create!(label: 'dummy', number: '+41790000000')
      patch :update, params: {
        group_id: group.id,
        event_id: course.id,
        event_participation_contact_data: {
          gender: 'm',
          email: person.email,
          first_name: person.first_name,
          birthday: '01.01.2002',
          address: 'Musterplatz',
          zip_code: 1234,
          town: 'Zürich',
          country: 'CH',
          last_name: 'NewName',
          phone_numbers_attributes: {
            '1' => { id: number.id, label: number.label, number: '+41791111111', _destroy: false }
          }
        },
        event_role: {
          type: 'Event::Role::Participant'
        }
      }
      puts entry.errors.full_messages
      expect(entry).to have(0).errors
      expect(person.reload.last_name).to eq 'NewName'
    end
  end
end
