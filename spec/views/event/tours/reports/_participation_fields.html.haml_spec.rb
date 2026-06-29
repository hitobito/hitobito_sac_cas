# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "event/tours/reports/_participation_fields.html.haml" do
  include FormatHelper

  let(:group) { groups(:bluemlisalp) }
  let(:event) { events(:section_tour) }
  let!(:participation) do
    Fabricate(Event::Role::Participant.name.to_sym,
      participation: Fabricate(:event_participation, participant: people(:mitglied), event: event)
    ).participation
  end
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
    assign(:group, group)
    assign(:event, event)
    allow(view).to receive(:entry).and_return(entry)
    allow(view).to receive(:f).and_return(form_builder)
  end

  it "renders state dropdown" do
    expect(dom).to have_css("select[name*='state']")
  end

  it "renders state text instead of dropdown when event is canceled" do
    event.update_column(:state, :canceled)

    expect(dom).to have_no_css("select[name*='state']")
    expect(dom).to have_text("Bestätigt")
  end

  it "renders state text instead of dropdown when participation state is not editable" do
    participation.update_columns(state: "canceled")

    expect(dom).to have_no_css("select[name*='state']")
    expect(dom).to have_text("Abgemeldet")
  end

  it "renders means_of_transport dropdown" do
    expect(dom).to have_css("select[name*='means_of_transport']")
  end

  it "renders state text instead of dropdown when event is canceled" do
    event.update_column(:state, :canceled)

    expect(dom).to have_no_css("select[name*='state']")
    expect(dom).to have_text("Bestätigt")
  end
end
