# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::EintritteExportJob do
  let(:user) { people(:admin) }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:from) { Date.new(2015, 1, 1) }
  let(:to) { Date.new(2015, 12, 31) }
  let(:file) { job.job_observation }

  subject(:job) { described_class.new(user.id, group.id, "eintritte", from, to) }

  it "creates a XLSX-Export" do
    expect_any_instance_of(Axlsx::Worksheet)
      .to receive(:add_row)
      .exactly(5).times
      .and_call_original

    expect { job.enqueue! }.to change { JobObservation.count }.by(1)
    job.perform

    expect(file.filename).to eq("eintritte.xlsx")
  end
end
