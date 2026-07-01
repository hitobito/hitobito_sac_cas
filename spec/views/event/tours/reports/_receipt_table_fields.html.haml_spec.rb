# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "event/tours/reports/_receipt_table_fields.html.haml" do
  include FormatHelper

  let(:group) { groups(:bluemlisalp) }
  let(:event) { events(:section_tour) }
  let(:report) { event_reports(:section_tour_report) }
  let(:receipt) { event_cost_receipts(:tankstelle) }
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
    assign(:group, group)
    assign(:event, event)
    allow(view).to receive(:entry).and_return(entry)
    allow(view).to receive(:f).and_return(form_builder)
    allow(entry).to receive(:receipts).and_return([receipt])
  end

  it "renders a link to the file instead of file input" do
    expect(dom).to have_link(receipt.file.filename.to_s)
    expect(dom).to have_no_css("input[type='file']")
  end

  it "renders a file input if no file attached" do
    receipt.file.detach

    expect(dom).to have_css("input[type='file']")
  end
end
