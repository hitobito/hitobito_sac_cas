# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::CheckDataQualityErrors do
  let(:person) { people(:familienmitglied) }
  let(:wizard) { double(person:) }

  subject(:step) { described_class.new(wizard) }

  describe "validations" do
    it "is valid without data quality errors" do
      expect(step).to be_valid
    end

    it "is invalid if data quality errors exist" do
      person.update!(data_quality: :error)
      expect(step).not_to be_valid
      expect(step.errors[:base].first).to match(/kann wegen ungültigen Daten nicht durchgeführt werden/)
    end

    it "is invalid if a household person has data quality errors" do
      person.household_people.last.update!(data_quality: :error)
      expect(step).not_to be_valid
      expect(step.errors[:base].first).to match(/kann wegen ungültigen Daten nicht durchgeführt werden/)
    end
  end
end
