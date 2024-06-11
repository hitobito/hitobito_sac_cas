# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Event::ParticipationBanner do

  include LayoutHelper
  include UtilityHelper

  let(:group) { Fabricate.build(:group, id: 1) }
  let(:event) { Fabricate.build(:course, id: 1, groups: [group], state: 'open') }
  let(:participation) do
    Fabricate.build(:event_participation, id: 1, event: event, application_id: -1, state: 'applied')
  end
  let(:name) { [participation.person.first_name, participation.person.last_name].join(' ') }
  let(:dom) { Capybara::Node::Simple.new(banner.render) }
  subject(:banner) { described_class.new(participation, participation.event, self) }
  let(:ability) { Ability.new(participation.person) }

  delegate :can?, to: :ability

  before do
    @virtual_path = "event/participations/actions_show_youth"
    controller.controller_path = 'event/participations'
    controller.request.path_parameters[:group_id] = group.id
    controller.request.path_parameters[:event_id] = event.id
    controller.request.path_parameters[:id] = participation.id
    assign(:group, group)
    assign(:event, event)
    allow(view).to receive(:entry).and_return(participation)
    allow(self).to receive(:parent).and_return(event)
    allow(self).to receive(:current_user).and_return(participation.person)
  end

  context 'applications are not cancelable' do
    it 'does not render button Abmelden' do
      expect(dom).not_to have_button 'Abmelden'
    end
  end

  context 'applications are cancelable' do
    before do
      event.applications_cancelable = true
      event.dates.build(start_at: 1.day.from_now)
    end

    it 'does render Abmelden button' do
      expect(dom).to have_button 'Abmelden'
    end

    it 'does render cancel form in popover' do
      button = dom.find_button 'Abmelden'
      expect(button['data-bs-toggle']).to eq 'popover'

      popover = Capybara::Node::Simple.new(button['data-bs-content'])
      expect(popover).to have_css "form[action='/de/groups/1/events/1/participations/1/cancel']"
      expect(popover).to have_field 'Begründung'
    end

    it 'hides Abmelden button when not permitted because participation has no application' do
      participation.application_id = nil
      expect(dom).not_to have_button 'Abmelden'
    end

    it 'hides Abmelden button when state does not allow cancel' do
      participation.state = 'rejected'
      expect(dom).not_to have_button 'Abmelden'
    end
  end

  context 'participation states' do
    it 'shows the correct flash message' do
      t('event.participations.states').each do |state, msg|
        participation.state = state
        dom = Capybara::Node::Simple.new(banner.render)

        expect(dom).to have_text msg
      end
    end
  end
end
