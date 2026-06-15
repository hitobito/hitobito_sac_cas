# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "events/_form_tab_pane_prices.html.haml" do
  include FormatHelper

  let(:form_builder) { StandardFormBuilder.new(:event, event, view, {}) }
  let(:dom) {
    render(locals: {f: form_builder})
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    allow(view).to receive_messages(entry: event.decorate)
  end

  context "course" do
    let(:event) { events(:top_course) }

    before do
      allow(view).to receive(:course?).and_return(true)
      allow(view).to receive(:tour?).and_return(false)
    end

    it "renders price fields with category labels" do
      expect(dom).to have_field "Mitgliederpreis"
      expect(dom).to have_field "Normalpreis"
      expect(dom).to have_field "Subventionierter Preis"
      expect(dom).to have_field "Spezialpreis"
    end
  end

  context "tour" do
    let(:event) { events(:section_tour) }

    before do
      allow(view).to receive(:course?).and_return(false)
      allow(view).to receive(:tour?).and_return(true)
    end

    it "renders price categories" do
      expect(dom).to have_text "Kosten SAC Sektionsmitglied"
      expect(dom).to have_text "Kosten SAC-Mitglied (extern)"
      expect(dom).to have_text "Kosten nicht-SAC-Mitglied (Gast)"
    end

    it "disables price field when may_apply is false" do
      event.special_may_apply = false
      expect(dom.find("fieldset", text: "Kosten SAC Sektionsmitglied")).to have_field("Kosten", disabled: true)
      expect(dom.find("fieldset", text: "Kosten SAC-Mitglied (extern)")).to have_field("Kosten", disabled: false)
    end
  end
end
