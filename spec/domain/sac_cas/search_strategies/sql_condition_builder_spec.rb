# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"
describe SearchStrategies::SqlConditionBuilder do
  def build(search_string, search_tables_and_fields)
    described_class.new(search_string, search_tables_and_fields)
      .search_conditions&.to_sql&.delete("`")
  end

  it "builds query for single field" do
    expect(build("test", %w[people.first_name])).to eq "\"people\".\"first_name\" ILIKE '%test%'"
  end

  it "builds query for multiple fields" do
    conditions = build("test", %w[people.first_name people.last_name])
    expect(conditions).to eq "(\"people\".\"first_name\" ILIKE '%test%' OR \"people\".\"last_name\" ILIKE '%test%')"
    expect(Person.where(conditions)).to be_empty
  end

  describe "birthday" do
    let(:person) { people(:admin) }

    it "uses custom matcher for birthday" do
      expect(build("1.10.2014", %w[people.birthday])).to eq "TO_CHAR(\"people\".\"birthday\", 'DD.MM.YYYY') ILIKE '%01.10.2014%'"
      expect(build("01.10.2014", %w[people.birthday])).to eq "TO_CHAR(\"people\".\"birthday\", 'DD.MM.YYYY') ILIKE '%01.10.2014%'"
      expect(build("01.10", %w[people.birthday])).to eq "TO_CHAR(\"people\".\"birthday\", 'DD.MM.YYYY') ILIKE '%01.10%'"
      expect(build("2014", %w[people.birthday])).to eq "TO_CHAR(\"people\".\"birthday\", 'DD.MM.YYYY') ILIKE '%2014%'"
    end

    it "finds person by birthday" do
      person.update!(birthday: Date.new(2013, 10, 1))
      expect(Person.where(build("1.10.2013", %w[people.birthday]))).to eq [person]
      expect(Person.where(build("01.10.2013", %w[people.birthday]))).to eq [person]
      expect(Person.where(build("01.10", %w[people.birthday]))).to include(person)
      expect(Person.where(build("2013", %w[people.birthday]))).to include(person)
    end

    it "ignores word without numbers" do
      expect(build("asdf", %w[people.birthday])).to be_nil
    end
  end

  describe "id" do
    let(:person) { people(:admin) }

    it "matches id using like" do
      expect(build(person.id.to_s, %w[people.id])).to eq "people.id::text ILIKE '%#{person.id}%'"
    end

    it "ignores non digit only word" do
      expect(build("test-#{person.id}", %w[people.id])).to be_nil
    end
  end
end
