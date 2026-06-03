# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::JubilareExportJob do
  let(:user) { people(:admin) }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:reference_date) { Date.new(2025, 10, 1) }
  let(:membership_years) { nil }
  let(:file) { job.job_observation }

  subject(:job) { described_class.new(user.id, group.id, "jubilare", reference_date, membership_years) }

  it "creates a XLSX-Export" do
    expect_any_instance_of(Axlsx::Worksheet)
      .to receive(:add_row)
      .exactly(5).times
      .and_call_original

    expect { job.enqueue! }.to change { JobObservation.count }.by(1)
    job.perform

    expect(file.filename).to eq("jubilare.xlsx")
  end
end
