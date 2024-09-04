# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::DataQualityChecker do
  let(:person) { people(:mitglied) }
  let(:checker) { described_class.new(person) }

  it "creates issues" do
    expect_query_count do
      expect { checker.check_data_quality }.to change { person.reload.data_quality_issues.count }.by(1)
    end.to eq(11)

    issue = person.data_quality_issues.first
    expect(issue).to have_attributes(
      attr: "phone_numbers",
      key: "empty",
      severity: "warning"
    )
    expect(person.data_quality).to eq("warning")
  end

  it "performs no queries if everything is ok" do
    person.data_quality_issues.create!(attr: :phone_numbers, key: :empty, severity: "warning")
    person.update_column(:data_quality, "warning")

    # preload all data
    person.reload
    person.roles.to_a
    person.data_quality_issues.to_a
    person.phone_numbers.to_a

    expect do
      expect_query_count { checker.check_data_quality }.to eq(0)
    end.not_to change { person.data_quality_issues.count }
  end

  it "destroys old issues and keeps existing" do
    person.data_quality_issues.create!(attr: :phone_numbers, key: :empty, severity: "warning")
    person.data_quality_issues.create!(attr: :last_name, key: :empty, severity: "error")
    person.update_column(:data_quality, "error")

    expect { checker.check_data_quality }.to change { person.reload.data_quality_issues.count }.by(-1)
    expect(person.data_quality).to eq("warning")
    expect(person.data_quality_issues.first.attr).to eq("phone_numbers")
  end
end
