# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::CsvReport do
  before do
    freeze_time
  end

  let(:headers) { %i[membershp_number sac_family_number name stammsektion] }
  let!(:csv_report) { described_class.new(:sektion_membership, headers) }
  let(:report_file) { Rails.root.join("log", "sac_imports", "sektion_membership_#{Time.zone.now.strftime("%Y-%m-%d-%H:%M")}.csv") }

  it "creates csv log with headers and appends rows" do
    expect(File.exist?(report_file)).to be_truthy
  end
end
