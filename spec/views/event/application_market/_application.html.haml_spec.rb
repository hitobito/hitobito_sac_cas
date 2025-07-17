#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event/application_market/_application.html.haml" do
  let(:event) { events(:top_course).decorate }
  let(:group) { event.groups.first.decorate }
  let(:participation) { event_participations(:top_mitglied) }
  let(:on_click_selector) { "a[onclick]" }

  subject(:dom) { Capybara::Node::Simple.new(render(locals: {p: participation.decorate})) }

  before do
    assign(:event, event)
    assign(:group, group)
    allow(view).to receive(:event).and_return(event)
  end

  it "renders application link" do
    expect(dom).to have_css on_click_selector
  end

  it "hides application link if event is canceled" do
    event.update_column(:state, :canceled)
    expect(dom).not_to have_css on_click_selector
  end
end
