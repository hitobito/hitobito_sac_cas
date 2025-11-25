# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Xlsx::MitgliederStatistics::SectionActive do
  let(:group) { groups(:bluemlisalp_mitglieder) }

  let(:range) { Date.new(2024, 1, 1)..Date.new(2024, 12, 31) }
  let(:section) { described_class.new(group, range) }

  before do
    # household with child turning 18 in 2022
    main = child1 = child2 = household = nil
    travel_to(Time.zone.local(2017, 6, 13)) do
      main = Fabricate(:person, birthday: "1978-11-14", sac_family_main_person: true,
        gender: :w, language: :de)
      create_role(person: main, start_on: "2017-06-13", end_on: "2022-12-31")
      child1 = Fabricate(:person, birthday: "2004-08-21", gender: :m, language: :fr)
      child2 = Fabricate(:person, birthday: "2009-03-04", gender: :w, language: :fr)
      household = Household.new(main).add(child1).add(child2)
      household.save || raise(household.errors.full_messages.join(", "))

      child1.roles.first.update!(end_on: "2022-12-31")
      child2.roles.first.update!(end_on: "2022-12-31")

      # role ending in 2022 is ignored
      # create_role(start_on: "2017-04-01", end_on: "2022-07-31")
    end

    create_role(person: main, start_on: "2023-01-01")
    create_role(person: child2, start_on: "2023-01-01", beitragskategorie: :youth)
    create_role(person: child1, start_on: "2023-01-01", beitragskategorie: :youth)

    Fabricate("Group::SektionsMitglieder::Leserecht", group:) # non-member roles are ignored
  end

  def create_role(**attrs)
    Fabricate(
      "Group::SektionsMitglieder::Mitglied",
      attrs.reverse_merge(group:, beitragskategorie: :adult)
    )
  end

  it "calculates total" do
    expect(section.total).to eq(7)
  end

  it "groups by gender" do
    expect(section.counts(:gender)).to eq(
      {"m" => 1, "w" => 3, nil => 3}
    )
  end

  it "groups by language" do
    expect(section.counts(:language)).to eq(
      {"de" => 5, "fr" => 2, "it" => 0, "en" => 0}
    )
  end

  it "groups by age" do
    expect(section.counts(:age)).to eq(
      {"6-17" => 2, "18-22" => 1, "23-35" => 3, "36-50" => 1, "51-60" => 0, "61+" => 0}
    )
  end

  it "groups by beitragskategorie" do
    expect(section.counts(:beitragskategorie)).to eq(
      {"adult" => 2, "family_main" => 1, "family_adult" => 1, "family_child" => 1, "youth" => 2}
    )
  end

  context "in previous year" do
    let(:range) { Date.new(2022, 1, 1)..Date.new(2022, 12, 31) }

    it "groups by age" do
      expect(section.counts(:age)).to eq(
        {"6-17" => 2, "18-22" => 2, "23-35" => 2, "36-50" => 1, "51-60" => 0, "61+" => 0}
      )
    end

    it "groups by beitragskategorie" do
      expect(section.counts(:beitragskategorie)).to eq(
        {"adult" => 1, "family_main" => 2, "family_adult" => 1, "family_child" => 3, "youth" => 0}
      )
    end
  end

  context "mid year" do
    let(:range) { Date.new(2022, 9, 1)..Date.new(2023, 3, 31) }

    it "groups by age" do
      expect(section.counts(:age)).to eq(
        {"6-17" => 2, "18-22" => 1, "23-35" => 3, "36-50" => 1, "51-60" => 0, "61+" => 0}
      )
    end

    it "groups by beitragskategorie" do
      expect(section.counts(:beitragskategorie)).to eq(
        {"adult" => 2, "family_main" => 1, "family_adult" => 1, "family_child" => 1, "youth" => 2}
      )
    end
  end
end
