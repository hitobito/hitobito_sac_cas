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

    it "checks the data quality of all persons" do
      expect { job.perform }.to change(person.data_quality_issues, :count)
    end
  end
end
