# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "event/participations/_summary_step.html.haml" do
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
    assign(:group, event.groups.first)
  end

  context "course" do
    let(:event) { events(:top_course) }

    it "renders annulation remarks" do
      expect(dom).to have_css ".alert-info"
    end

    it "renders checkboxes" do
      expect(dom).to have_css "input[name='event_participation[adult_consent]']"
      expect(dom).to have_css "input[name='event_participation[terms_and_conditions]']"
    end
  end

  context "tour" do
    let(:event) { events(:section_tour) }

    it "does not render annulation remarks or checkboxes" do
      expect(dom).not_to have_css ".alert-info"
      expect(dom).not_to have_css "input[name='event_participation[adult_consent]']"
      expect(dom).not_to have_css "input[name='event_participation[terms_and_conditions]']"
    end
  end
end
