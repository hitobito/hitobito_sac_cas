# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Sheet::Event::Tours::Report do
  let(:report) { event_reports(:section_tour_report) }
  let(:form) { instance_double(Event::Tour::ReportForm, report: report) }

  before { allow(view).to receive(:entry).and_return(form) }

  it "uses report status as title" do
    sheet = described_class.new(view)
    expect(sheet.title).to eq "Tourenrapport (Entwurf)"
  end
end
