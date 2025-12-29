# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Events::AnnualCoursesDuplicator do
  let(:duplicator) { described_class.new(2025, 2026) }

  around do |example|
    travel_to(Time.zone.local(2025, 10, 10)) do
      example.run
    end
  end

  let!(:annual_courses_in_source_year) do
    (1..10).map do |i|
      Fabricate(:sac_open_course, number: "2025-#{i}", annual: true)
    end
  end

  let!(:non_annual_courses_in_source_year) do
    (11..13).map do |i|
      Fabricate(:sac_open_course, number: "2025-#{i}", annual: false)
    end
  end

  let!(:annual_courses_in_other_year) do
    (0..2).map do |i|
      Fabricate(:sac_open_course, number: "2024-#{i}", annual: true)
    end
  end

  context "#courses_to_duplicate" do
    let(:courses_to_duplicate) { duplicator.send(:courses_to_duplicate) }

    it "finds courses with annual in source year" do
      expect(courses_to_duplicate).to match_array(annual_courses_in_source_year)
    end

    it "does not find courses without annual in source year" do
      expect(courses_to_duplicate).to_not include(non_annual_courses_in_source_year)
    end

    it "does not find courses with annual in other year" do
      expect(courses_to_duplicate).to_not include(annual_courses_in_other_year)
    end
  end

  context "#run" do
    it "duplicates courses" do
      expect do
        duplicator.run
      end.to change { Event::Course.count }.by(10)
    end
  end
end
