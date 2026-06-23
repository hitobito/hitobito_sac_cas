#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event/participations/_answers_step.html.haml" do
  include FormatHelper

  let(:participation) { event_participations(:top_mitglied) }
  let(:form_builder) { StandardFormBuilder.new(:event_participation, participation, view, {}) }
  let(:dom) {
    render(locals: {f: form_builder})
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    allow(view).to receive_messages(entry: participation.decorate)
    assign(:event, event.decorate)
    assign(:answers, [])
  end

  context "event" do
    let(:event) { events(:top_event) }

    it "does not render means of transport" do
      expect(dom).to have_no_text "Anreisemittel"
    end

    it "does not render actual days" do
      expect(dom).to have_no_text "Effektive Tage"
    end
  end

  context "course" do
    let(:event) { events(:top_course) }

    context "without update_full permission" do
      before { allow(view).to receive(:can?).and_return(false) }

      it "does not render means of transport" do
        expect(dom).to have_no_text "Anreisemittel"
      end

      it "does not render actual days" do
        expect(dom).to have_no_text "Effektive Tage"
      end
    end

    context "with update_full permission" do
      before { allow(view).to receive(:can?).and_return(true) }

      it "renders actual days" do
        expect(dom).to have_text "Effektive Tage"
      end
    end
  end

  context "tour" do
    let(:event) { events(:section_tour) }

    it "renders means of transport" do
      expect(dom).to have_text "Anreisemittel"
    end

    it "does not render actual days" do
      expect(dom).to have_no_text "Effektive Tage"
    end
  end
end
