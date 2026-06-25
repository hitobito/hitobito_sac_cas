#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event/participations/_center_fields_sac_cas.html.haml" do
  include FormatHelper

  let(:participation) { event_participations(:top_mitglied) }
  let(:form_builder) { StandardFormBuilder.new(:event_participation, participation, view, {}) }
  let(:dom) {
    render(locals: {f: form_builder})
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    assign(:event, event.decorate)
  end

  context "event" do
    let(:event) { events(:top_event) }

    it "does not render means of transport" do
      expect(dom).to have_no_text "Anreisemittel"
    end
  end

  context "course" do
    let(:event) { events(:top_course) }

    it "does not render means of transport" do
      expect(dom).to have_no_text "Anreisemittel"
    end
  end

  context "tour" do
    let(:event) { events(:section_tour) }

    it "renders means of transport" do
      expect(dom).to have_text "Anreisemittel"
    end
  end
end
