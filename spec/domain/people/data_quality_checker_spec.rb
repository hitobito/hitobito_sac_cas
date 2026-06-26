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
    expect do
      expect { checker.check_data_quality }.to change { person.reload.data_quality_issues.count }.by(1)
    end.to make(13).db_queries

    issue = person.data_quality_issues.first
    expect(issue).to have_attributes(
      attr: "phone_numbers",
      key: "empty",
      severity: "warning"
    )
    expect(person.data_quality).to eq("warning")
  end

  describe "street is blank" do
    it "creates issue" do
      person.update_columns(street: nil)
      checker.check_data_quality
      expect(person.data_quality_issues.map(&:attr)).to include "street"
    end

    it "does not create issue if postbox is present" do
      person.update_columns(street: nil, postbox: "test")
      checker.check_data_quality
      expect(person.data_quality_issues.map(&:attr)).not_to include "street"
    end

    it "clears existing issue if postbox is present" do
      person.update_columns(street: nil, postbox: "Postfach xy")
      person.data_quality_issues.create!(attr: :street, key: :empty, severity: :error)
      checker.check_data_quality
      expect(person.reload.data_quality_issues.map(&:attr)).not_to include "street"
    end

    it "does not create issue if postbox is blank for relaxed zip_code" do
      person.update_columns(street: nil, zip_code: 1148)
      checker.check_data_quality
      expect(person.data_quality_issues.map(&:attr)).not_to include "street"
    end
  end

  it "performs only membership invoicable queries if everything is ok" do
    person.data_quality_issues.create!(attr: :phone_numbers, key: :empty, severity: "warning")
    person.update_column(:data_quality, "warning")

    # preload all data
    person.reload
    person.roles.to_a
    person.data_quality_issues.to_a
    person.phone_numbers.to_a

    expect do
      expect { checker.check_data_quality }.to make(2).db_queries
    end.not_to change { person.data_quality_issues.count }
  end

  describe "birthday minimum age check" do
    let(:stammsektion_role) { roles(:mitglied) }

    before do
      stammsektion_role.update_columns(created_at: Time.zone.parse("2020-06-15"))
    end

    it "creates no issue when person was born at end of year 6 years ago" do
      person.update_columns(birthday: Date.new(2014, 12, 31))
      checker.check_data_quality
      expect(person.data_quality_issues.map(&:key)).not_to include "less_than_6_years_before_entry"
    end

    it "creates issue when person was born on first day after end of year 6 years ago" do
      person.update_columns(birthday: Date.new(2015, 1, 1))
      checker.check_data_quality
      expect(person.data_quality_issues.map(&:key)).to include "less_than_6_years_before_entry"
    end
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
