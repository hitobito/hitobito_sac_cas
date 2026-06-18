#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "events/_attrs_main_sac_cas.html.haml" do
  include FormatHelper

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    allow(view).to receive_messages(entry: EventDecorator.decorate(event))
  end

  context "event" do
    let(:event) { events(:top_event) }

    it "does not render id" do
      expect(dom).not_to have_text "Event-ID"
    end
  end

  context "course" do
    let(:event) { events(:top_course) }

    it "does not render id" do
      expect(dom).not_to have_text "Event-ID"
    end
  end

  context "tour" do
    let(:event) { events(:section_tour) }

    it "does render id" do
      expect(dom).to have_text "Event-ID"
    end
  end
end
