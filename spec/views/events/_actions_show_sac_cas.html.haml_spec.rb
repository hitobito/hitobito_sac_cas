# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "events/_actions_show_sac_cas.html.haml" do
  let(:group) { groups(:bluemlisalp) }
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    assign(:group, group)
    allow(event).to receive(:states?).and_return(false)
    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive_messages(entry: EventDecorator.decorate(event))
  end

  context "event" do
    let(:event) { events(:top_event) }

    it "does not render course or tour specific actions" do
      expect(dom).to have_no_text "Alle Eckdatenblätter erzeugen"
      expect(dom).to have_no_text "Freigabe"
      expect(dom).to have_no_text "Tourenrapport"
    end
  end

  context "course" do
    let(:event) { events(:top_course) }

    it "renders course specific actions" do
      expect(dom).to have_text "Alle Eckdatenblätter erzeugen"
    end

    it "does not render tour specific actions" do
      expect(dom).to have_no_text "Freigabe"
      expect(dom).to have_no_text "Tourenrapport"
    end
  end

  context "tour" do
    let(:event) { events(:section_tour) }

    it "renders tour specific buttons" do
      allow(event).to receive(:reportable?).and_return(true)

      expect(dom).to have_text "Freigabe"
      expect(dom).to have_text "Tourenrapport"
    end

    it "does not render report button when not reportable" do
      allow(event).to receive(:reportable?).and_return(false)
      expect(dom).to have_no_text "Tourenrapport"
    end

    it "does not render course specific actions" do
      expect(dom).to have_no_text "Alle Eckdatenblätter erzeugen"
    end
  end
end
