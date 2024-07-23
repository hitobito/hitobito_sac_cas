# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::MembershipYearsReport do
  let(:report) { described_class.new }
  let(:report_file) { Rails.root.join("log", "sac_imports", "membership_years_report_#{Time.zone.now.strftime("%Y-%m-%d-%H:%M")}.csv") }

  it "exits with error if NAV2 source file not available" do
    expect do
      report
    end.to raise_error("No source file NAV2_*.xlsx found in RAILS_CORE_ROOT/tmp/xlsx/.")
  end

 it "creates report for members in source file" do
   report.create
  end
end
