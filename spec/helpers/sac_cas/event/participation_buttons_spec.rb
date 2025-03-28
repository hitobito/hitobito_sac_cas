# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth

require "spec_helper"

describe Event::ParticipationButtons do
  include LayoutHelper
  include UtilityHelper

  let(:person) { Person.new(id: 1) }
  let(:group) { Fabricate.build(:group, id: 1) }
  let(:event) { Fabricate.build(:course, id: 1, groups: [group], state: "open") }
  let(:participation) { Fabricate.build(:event_participation, id: 1, event: event) }
  let(:dom) { Capybara::Node::Simple.new(buttons.to_s) }

  subject(:buttons) { described_class.new(self, participation) }

  before do
    @virtual_path = "event/participations/actions_show_youth"
    controller.controller_path = "event/participations"
    controller.request.path_parameters[:group_id] = group.id
    controller.request.path_parameters[:event_id] = event.id
    controller.request.path_parameters[:id] = participation.id
    assign(:group, group)
    assign(:event, event)
    allow(self).to receive(:can?).and_return(true)
    allow(view).to receive(:entry).and_return(participation)
    allow(self).to receive(:current_user).and_return(person)
    allow(view).to receive(:current_user).and_return(person)
  end

  shared_examples "conditional action" do |label, states:, condition: nil, assert: :link|
    let(:assertion) { "have_#{assert}" }

    states.each do |state|
      it "render #{label} #{assert} for participation in #{state}" do
        participation.state = state
        expect(dom).to send(assertion, label)
      end
    end

    (Event::Course.possible_participation_states - states).each do |state|
      it "hides #{label} #{assert} for participation in #{state}" do
        participation.state = state
        expect(dom).not_to send(assertion, label)
      end
    end
  end

  it_behaves_like "conditional action", "Abmelden", states: %w[unconfirmed applied assigned summoned], assert: :button do
    context "his own participation" do
      before do
        participation.person = person
        participation.state = "assigned"
        event.dates.build(start_at: 3.days.from_now)
      end

      it "shows button when participant_cancelable" do
        event.applications_cancelable = true
        expect(participation).to be_participant_cancelable
        expect(dom).to have_button("Abmelden")
      end

      it "does not show button when not participant_cancelable" do
        event.applications_cancelable = false
        expect(participation).not_to be_participant_cancelable
        expect(dom).not_to have_button("Abmelden")
      end
    end
  end

  it_behaves_like "conditional action", "Ablehnen", states: %w[unconfirmed applied]
  it_behaves_like "conditional action", "Nicht erschienen", states: %w[assigned attended summoned]

  describe "Aufgeboten" do
    it_behaves_like "conditional action", "Aufbieten", states: [], assert: :button
    it_behaves_like "conditional action", "Aufbieten", states: %w[assigned], assert: :button do
      before { event.state = "ready" }
    end
  end

  describe "Teilgenommen" do
    it_behaves_like "conditional action", "Teilgenommen", states: []
    it_behaves_like "conditional action", "Teilgenommen", states: %w[absent] do
      before { event.state = "closed" }
    end
  end

  describe "Zugeteilt" do
    it_behaves_like "conditional action", "Zugeteilt", states: %w[applied absent]
    it_behaves_like "conditional action", "Zugeteilt", states: %w[] do
      before { event.state = "closed" }
    end
  end
end
