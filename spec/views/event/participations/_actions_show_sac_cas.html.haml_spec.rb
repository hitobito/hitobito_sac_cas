# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event/participations/_actions_show_sac_cas.html.haml" do
  let(:participation) { event_participations(:top_mitglied) }
  let(:event) { participation.event }
  let(:group) { event.groups.first }
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    assign(:group, group)
    assign(:event, event)
    assign(:participation, participation)
    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive_messages(entry: Event::ParticipationDecorator.decorate(participation))
    event.state = "closed"
    participation.state = "attended"
  end

  it "renders attendance confirmation button" do
    expect(dom).to have_link "Teilnahmebestätigung",
      href: "/de/groups/#{group.id}/events/#{event.id}/participations/#{participation.id}/attendance_confirmation"
  end

  it "does not render attendance confirmation button if participation is not attendance confirmable" do
    participation.state = "absent"
    expect(dom).to have_no_link "Teilnahmebestätigung"
  end

  it "does not render attendance confirmation button without show_details permission" do
    allow(view).to receive(:can?).with(:show_details, participation).and_return(false)
    expect(dom).to have_no_link "Teilnahmebestätigung"
  end
end
