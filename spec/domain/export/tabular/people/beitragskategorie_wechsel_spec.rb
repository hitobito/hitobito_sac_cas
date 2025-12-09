# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::People::BeitragskategorieWechsel do
  let(:user) { people(:admin) }
  let(:bluemlisalp) { groups(:bluemlisalp_mitglieder) }
  let(:matterhorn) { groups(:matterhorn_mitglieder) }

  def create_role(beitragskategorie, group = groups(:bluemlisalp_mitglieder), **attrs)
    Fabricate("Group::SektionsMitglieder::Mitglied", group:, beitragskategorie:, **attrs)
  end

  def build(range_string = "1.7.2024-30.6.2025", group = nil)
    from, to = range_string.split("-").map { |s| Date.parse(s) }
    described_class.new(group || bluemlisalp, user.id, from..to)
  end

  it "has expected attributes" do
    expect(build.attributes).to eq [
      :id,
      :url,
      :sektion,

      :changed_on,
      :changed_youth_adult,
      :changed_youth_family,
      :changed_adult_family,
      :changed_family_adult,
      :changed_family_youth,

      :type,
      :beitragskategorie,
      :membership_years,
      :sac_entry_on,
      :sektion_entry_on,
      :ehrenmitglied,
      :beguenstigt,

      :last_name,
      :first_name,
      :gender,
      :birthday,
      :correspondence,
      :email,
      :phone_number_mobile,
      :phone_number_landline,
      :postbox,
      :street,
      :housenumber,
      :address_care_of,
      :zip_code,
      :town,
      :country
    ]
  end

  it "has range in sheet name" do
    expect(build.sheet_name).to eq "20240701_20250630"
  end

  describe "#people_scope" do
    subject(:people_scope) { build.people_scope }

    it "testing most common cases" do
      youth2adult = create_role("youth", start_on: "1.1.2024", end_on: "31.12.2024").person
      create_role("adult", start_on: "1.1.2025", person: youth2adult)

      earlier = create_role("youth", start_on: "1.1.2024", end_on: "30.5.2024").person
      create_role("adult", start_on: "31.5.2024", person: earlier)

      adult2family = create_role("adult", start_on: "1.1.2024", end_on: "9.6.2024").person
      adult2family.update!(sac_family_main_person: true)
      create_role("family", start_on: "10.6.2024", person: adult2family)

      family2adult = create_role("family", start_on: "1.1.2024", end_on: "10.10.2024").person
      create_role("adult", start_on: "11.10.2024", person: family2adult)

      family2youth = create_role("family", start_on: "1.1.2024", end_on: "31.12.2024").person
      create_role("youth", start_on: "1.1.2025", person: family2youth)

      youth2family = create_role("youth", start_on: "1.1.2024", end_on: "3.3.2025").person
      youth2family.update!(sac_family_main_person: true)
      create_role("family", start_on: "3.4.2025", person: youth2family)

      youth2youth = create_role("youth", start_on: "1.1.2024", end_on: "31.12.2024").person
      create_role("youth", start_on: "1.1.2025", person: youth2youth)

      family2adult2family = create_role("family", start_on: "1.1.2024", end_on: "31.12.2024").person
      family2adult2family.update!(sac_family_main_person: true)
      create_role("adult", start_on: "1.1.2025", end_on: "1.2.2025", person: family2adult2family)
      create_role("family", start_on: "2.2.2025", person: family2adult2family)

      youth2adult2youth = create_role("youth", start_on: "1.1.2024", end_on: "31.12.2024").person
      create_role("adult", start_on: "1.1.2025", end_on: "1.2.2025", person: youth2adult2youth)
      create_role("youth", start_on: "2.2.2025", person: youth2adult2youth)

      youth2adult_with_gap = create_role("youth", start_on: "1.1.2024", end_on: "31.12.2024").person
      create_role("adult", start_on: "2.1.2025", person: youth2adult_with_gap)

      expect(build("1.1.2024-30.6.2024").people_scope).to match_array [earlier, adult2family]
      expect(build("2.1.2024-30.6.2024").people_scope).to match_array [earlier, adult2family]
      expect(build("1.6.2024-31.12.2024").people_scope).to match_array [adult2family, family2adult]

      expect(build("1.6.2024-30.5.2025").people_scope.map(&:to_s)).to match_array [
        youth2adult,
        adult2family,
        family2adult,
        family2youth,
        youth2family,
        youth2adult_with_gap
      ].map(&:to_s)

      expect(build("1.1.2025-1.6.2025").people_scope.map(&:to_s)).to match_array [
        youth2adult,
        family2youth,
        youth2family
      ].map(&:to_s)

      expect(build("10.1.2025-1.6.2025").people_scope.map(&:to_s)).to match_array [
        youth2family,
        youth2adult2youth,
        family2adult2family
      ].map(&:to_s)

      expect(build("1.1.2026-31.12.2026").people_scope).to be_empty
    end
  end

  describe "data_rows" do
    let(:mitglied) { people(:mitglied) }
    let(:row_class) do
      Data.define(*described_class.attributes) do
        def to_s = [first_name, last_name].join(" ")
      end
    end
    let(:rows) { build.data_rows.map { |r| row_class.new(*r) } }

    def row_for(person, group = nil, range_string = nil)
      if group
        build_rows(range_string, group)
      else
        rows
      end.index_by(&:id)[person.id]
    end

    def build_rows(range_string, group = nil)
      build(range_string, group).data_rows.map { |r| row_class.new(*r) }
    end

    it "does not do N+1 queries" do
      create_role("youth", person: people(:mitglied), start_on: "1.1.2000", end_on: "31.12.2014")
      create_role("adult", person: people(:familienmitglied), start_on: "1.1.2000", end_on: "31.12.2014")
      create_role("adult", person: people(:familienmitglied2), start_on: "1.1.2000", end_on: "31.12.2014")
      tabular = build("1.1.2015-31.12.2015")

      expect_query_count do
        expect(tabular.data_rows).to have(3).items
      end.to eq(5)
    end

    describe "common" do
      let(:rows) { build_rows("1.1.2015-31.12.2015") }

      before do
        create_role("youth", person: people(:mitglied), start_on: "1.1.2000", end_on: "31.12.2014")
        create_role("adult", person: people(:familienmitglied), start_on: "1.1.2000", end_on: "31.12.2014")
        create_role("adult", person: people(:familienmitglied2), start_on: "1.1.2000", end_on: "31.12.2014")
      end

      it "contains all attributes" do
        mitglied.update!(
          address_care_of: "c/o Mami u Papi",
          postbox: "Postfach 1",
          gender: "m",
          birthday: "21.04.1972"
        )
        mitglied.phone_numbers.create!(label: "landline", number: "031 333 44 55")
        mitglied.phone_numbers.create!(label: "mobile", number: "079 333 44 55")

        expect(row_for(mitglied).to_h).to eq({
          id: 600001,
          url: "http://test.host/de/groups/380959420/people/600001/history",
          sektion: "SAC Blüemlisalp",
          changed_adult_family: "nein",
          changed_family_adult: "nein",
          changed_family_youth: "nein",
          changed_on: "01.01.2015",
          changed_youth_adult: "ja",
          changed_youth_family: "nein",
          membership_years: 25,
          sac_entry_on: "01.01.2000",
          sektion_entry_on: "01.01.2000",
          type: "Stammsektion",
          beitragskategorie: "Einzel",
          ehrenmitglied: "nein",
          beguenstigt: "nein",
          last_name: "Hillary",
          first_name: "Edmund",
          gender: "männlich",
          birthday: "21.04.1972",
          correspondence: "Digital",
          email: "e.hillary@hitobito.example.com",
          phone_number_mobile: "+41 79 333 44 55",
          phone_number_landline: "+41 31 333 44 55",
          postbox: "Postfach 1",
          street: "Ophovenerstrasse",
          housenumber: "79a",
          address_care_of: "c/o Mami u Papi",
          zip_code: "2843",
          town: "Neu Carlscheid",
          country: "CH"
        })
      end

      it "orders by name" do
        expect(rows.map(&:to_s)).to eq ["Edmund Hillary", "Frieda Norgay", "Tenzing Norgay"]
      end
    end

    describe "bk wechsel specific fields" do
      let(:rows) { build_rows("1.6.2024-31.5.2025") }

      it "marks youth to adult change" do
        person = create_role("youth", start_on: "1.1.2024", end_on: "31.12.2024").person
        create_role("adult", start_on: "1.1.2025", person: person)

        expect(row_for(person).changed_on).to eq "01.01.2025"
        expect(row_for(person).changed_youth_adult).to eq "ja"
        expect(row_for(person).changed_youth_family).to eq "nein"
        expect(row_for(person).changed_adult_family).to eq "nein"
        expect(row_for(person).changed_family_adult).to eq "nein"
        expect(row_for(person).changed_family_youth).to eq "nein"
      end

      it "marks youth to family change" do
        person = create_role("youth", start_on: "1.1.2024", end_on: "31.12.2024").person
        person.update!(sac_family_main_person: true)
        create_role("family", start_on: "1.1.2025", person: person)

        expect(row_for(person).changed_on).to eq "01.01.2025"
        expect(row_for(person).changed_youth_adult).to eq "nein"
        expect(row_for(person).changed_youth_family).to eq "ja"
        expect(row_for(person).changed_adult_family).to eq "nein"
        expect(row_for(person).changed_family_adult).to eq "nein"
        expect(row_for(person).changed_family_youth).to eq "nein"
      end

      it "marks adult to family change" do
        person = create_role("adult", start_on: "1.1.2024", end_on: "9.6.2024").person
        person.update!(sac_family_main_person: true)
        create_role("family", start_on: "10.6.2024", person: person)

        expect(row_for(person).changed_on).to eq "10.06.2024"
        expect(row_for(person).changed_youth_adult).to eq "nein"
        expect(row_for(person).changed_youth_family).to eq "nein"
        expect(row_for(person).changed_adult_family).to eq "ja"
        expect(row_for(person).changed_family_adult).to eq "nein"
        expect(row_for(person).changed_family_youth).to eq "nein"
      end

      it "marks family to adult change" do
        person = create_role("family", start_on: "1.1.2024", end_on: "10.10.2024").person
        create_role("adult", start_on: "11.10.2024", person: person)

        expect(row_for(person).changed_on).to eq "11.10.2024"
        expect(row_for(person).changed_youth_adult).to eq "nein"
        expect(row_for(person).changed_youth_family).to eq "nein"
        expect(row_for(person).changed_adult_family).to eq "nein"
        expect(row_for(person).changed_family_adult).to eq "ja"
        expect(row_for(person).changed_family_youth).to eq "nein"
      end

      it "marks family to youth change" do
        person = create_role("family", start_on: "1.1.2024", end_on: "31.12.2024").person
        create_role("youth", start_on: "1.1.2025", person: person)

        expect(row_for(person).changed_on).to eq "01.01.2025"
        expect(row_for(person).changed_youth_adult).to eq "nein"
        expect(row_for(person).changed_youth_family).to eq "nein"
        expect(row_for(person).changed_adult_family).to eq "nein"
        expect(row_for(person).changed_family_adult).to eq "nein"
        expect(row_for(person).changed_family_youth).to eq "ja"
      end

      it "uses latest ended and started roles in range for field calculation" do
        person = create_role("youth", start_on: "1.1.2024", end_on: "31.12.2024").person
        person.update!(sac_family_main_person: true)
        create_role("family", start_on: "1.1.2025", end_on: "31.1.2025", person:)
        create_role("adult", start_on: "1.2.2025", person: person)

        expect(row_for(person).changed_on).to eq "01.02.2025"
        expect(row_for(person).changed_youth_adult).to eq "nein"
        expect(row_for(person).changed_youth_family).to eq "nein"
        expect(row_for(person).changed_adult_family).to eq "nein"
        expect(row_for(person).changed_family_adult).to eq "ja"
        expect(row_for(person).changed_family_youth).to eq "nein"
      end
    end
  end
end
