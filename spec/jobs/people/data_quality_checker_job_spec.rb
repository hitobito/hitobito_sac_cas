# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::DataQualityCheckerJob do
  let!(:person) { Fabricate(:person, first_name: nil) }
  let(:job) { described_class.new }

  context "when performing job" do
    before { person.data_quality_issues.destroy_all }

    it "checks the data quality of all people" do
      batch_selects = 4
      issues_created = 6 # validation and insert
      affected_people = 4 # update data_quality
      expect do
        expect_query_count { job.perform }.to eq(batch_selects + issues_created * 2 + affected_people)
      end.to change { person.data_quality_issues.count }.by(1)
        .and change { Person::DataQualityIssue.count }.by(issues_created)
    end
  end
end
