# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event/tours/reports/_status_fields.html.haml" do
  include FormatHelper

  let(:event) { events(:section_tour) }
  let(:report) { event_reports(:section_tour_report) }
  let(:entry) { Event::Tour::ReportForm.new(report) }
  let(:form_builder) {
    StandardFormBuilder.new(:event_tour_report_form, entry, view, {
      builder: StandardFormBuilder
    })
  }
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    allow(view).to receive(:entry).and_return(entry)
    allow(view).to receive(:f).and_return(form_builder)
  end

  it "renders text area inputs for review and remarks" do
    expect(dom).to have_css("textarea#event_tour_report_form_review")
    expect(dom).to have_css("textarea#event_tour_report_form_remarks")
  end

  it "does not show canceled_reason" do
    expect(dom).to have_no_text("Absagegrund")
  end

  context "when event is canceled" do
    before { event.update_column(:state, :canceled) }

    it "shows canceled_reason" do
      expect(dom).to have_text("Absagegrund")
    end
  end
end
