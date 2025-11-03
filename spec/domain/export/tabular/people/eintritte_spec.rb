# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::People::Eintritte do
  let(:user) { people(:admin) }
  let(:bluemlisalp) { groups(:bluemlisalp_mitglieder) }
  let(:matterhorn) { groups(:matterhorn_mitglieder) }

  def create_role(type, group = groups(:bluemlisalp_mitglieder), **attrs)
    Fabricate("Group::SektionsMitglieder::#{type}", group:, **attrs)
  end

  def build(range_string = "1.7.2024-30.6.2025")
    from, to = range_string.split("-").map { |s| Date.parse(s) }
    described_class.new(bluemlisalp, user.id, from..to)
  end

  it "has expected attributes" do
    expect(build.attributes).to eq [
      :id,
      :url,
      :sektion,
      :sac_is_new_entry,
      :sac_is_re_entry,
      :sac_is_section_new_entry,
      :sac_is_section_change,
      :membership_years,
      :sac_entry_on,
      :sektion_entry_on,
      :terminate_on,
      :type,
      :beitragskategorie,
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
    expect(build.sheet_name).to eq "von_20240701_bis_20250630"
  end

  describe "#people_scope" do
    subject(:people_scope) { build.people_scope }

    it "testing most common cases" do
      stammsektion = create_role("Mitglied", start_on: "10.7.2024").person

      zusatzsektion = create_role("Mitglied", matterhorn, start_on: "3.2.2000").person
      create_role("MitgliedZusatzsektion", start_on: "30.6.2025", person: zusatzsektion)

      stammsektions_wechsel = create_role("Mitglied", matterhorn, start_on: "3.2.2000", end_on: "30.6.2024").person
      create_role("Mitglied", start_on: "1.7.2024", person: stammsektions_wechsel)

      bk_change = create_role("Mitglied", start_on: "1.1.2024", end_on: "31.12.2024").person
      bk_change.update!(sac_family_main_person: true)
      create_role("Mitglied", start_on: "1.1.2025", beitragskategorie: :family, person: bk_change)

      sac_re_entry = create_role("Mitglied", matterhorn, start_on: "3.2.2000", end_on: "30.6.2010").person
      create_role("Mitglied", start_on: "30.6.2025", person: sac_re_entry)

      section_re_entry = create_role("Mitglied", matterhorn, start_on: "3.2.2000").person
      create_role("MitgliedZusatzsektion", start_on: "30.6.2010", end_on: "30.6.2020", person: section_re_entry)
      create_role("MitgliedZusatzsektion", start_on: "1.7.2024", person: section_re_entry)

      with_gap = create_role("Mitglied", start_on: "30.6.2024", end_on: "31.12.2024").person
      create_role("Mitglied", start_on: "3.3.2025", person: with_gap)

      # not part of scope
      create_role("Mitglied", start_on: "1.7.2025").person # too new
      create_role("Ehrenmitglied", start_on: "1.1.2025").person # outside of roles scope

      too_new = create_role("Mitglied", matterhorn, start_on: "1.1.2025").person
      create_role("MitgliedZusatzsektion", start_on: "1.7.2025", person: too_new) # too new

      too_old = create_role("Mitglied", start_on: "30.6.2024").person # too old
      create_role("MitgliedZusatzsektion", matterhorn, start_on: "30.6.2025", person: too_old) # outside of group

      expect(people_scope).to have(5).entries
      expect(people_scope).to match_array [
        stammsektion,
        zusatzsektion,
        stammsektions_wechsel,
        sac_re_entry,
        section_re_entry
      ]

      expect(build("1.1.2024-29.6.2024").people_scope).to eq [bk_change]
      expect(build("30.6.2024-30.6.2024").people_scope).to match_array [with_gap, too_old]
      expect(build("1.1.2025-1.3.2025").people_scope).to be_empty
      expect(build("1.3.2025-1.5.2025").people_scope).to eq [with_gap]
      expect(build("1.1.2026-31.12.2026").people_scope).to be_empty
    end

    it "includes memberships with gap but excludes consecutive memberships" do
      prev_year = create_role("Mitglied", start_on: "1.1.2023", end_on: "1.2.2023").person
      create_role("Mitglied", start_on: "1.10.2023", end_on: "30.6.2024", person: prev_year)
      create_role("Mitglied", start_on: "1.7.2024", person: prev_year)

      same_year = create_role("Mitglied", start_on: "1.1.2024", end_on: "1.2.2024").person
      create_role("Mitglied", start_on: "1.4.2024", end_on: "30.6.2024", person: same_year)
      create_role("Mitglied", start_on: "1.7.2024", person: same_year)

      same_year_with_gap = create_role("Mitglied", start_on: "1.1.2024", end_on: "1.2.2024").person
      create_role("Mitglied", start_on: "1.4.2024", end_on: "29.6.2024", person: same_year_with_gap)
      create_role("Mitglied", start_on: "1.7.2024", person: same_year_with_gap)

      expect(build("10.10.2022-1.10.2023").people_scope).to eq [prev_year]
      expect(build("1.1.2023-10.1.2023").people_scope).to eq [prev_year]
      expect(build("1.3.2023-30.9.2023").people_scope).to eq []
      expect(build("1.4.2023-30.10.2023").people_scope).to eq [prev_year]
      expect(build("1.6.2023-30.10.2023").people_scope).to eq [prev_year]
      expect(build("1.7.2024-30.6.2025").people_scope).to match_array [same_year_with_gap]
      expect(build("1.3.2024-30.6.2025").people_scope).to match_array [same_year, same_year_with_gap]
      expect(build("1.6.2024-30.6.2025").people_scope).to be_empty # ap started to early / late, others consecutive
    end

    it "includes membership with multiple roles if all start within range" do
      person = create_role("Mitglied", start_on: "1.7.2024", end_on: "31.12.2024").person
      create_role("Mitglied", start_on: "1.1.2025", end_on: "28.2.2025", person:)
      create_role("Mitglied", start_on: "1.3.2025", person:)

      older = create_role("Mitglied", start_on: "1.7.2022", end_on: "30.6.2024").person
      create_role("Mitglied", start_on: "1.1.2025", end_on: "28.2.2025", person: older)
      create_role("Mitglied", start_on: "1.3.2025", person: older)

      expect(people_scope).to match_array [person]
    end

    it "includes membership with gap in wider but excludes in narrower range" do
      person = create_role("Mitglied", start_on: "1.7.2000", end_on: "1.3.2025").person
      create_role("Mitglied", start_on: "1.7.2025", person:)

      expect(build("1.1.2025-31.12.2025").people_scope).to eq [] # continuation
      expect(build("1.7.2025-31.12.2025").people_scope).to eq [person]
      expect(build("1.1.2025-1.5.2025").people_scope).to be_empty
      expect(build("1.1.2000-1.6.2000").people_scope).to eq []
      expect(build("1.1.2000-1.1.2001").people_scope).to eq [person]
    end

    it "excludes ended membership older than a year" do
      ended_but_started_outside = create_role("Mitglied", start_on: "1.7.2023", end_on: "30.6.2024").person
      create_role("Mitglied", start_on: "1.7.2024", end_on: "1.8.2024", person: ended_but_started_outside)

      started_and_ended_inside_range = create_role("Mitglied", start_on: "1.7.2024", end_on: "1.8.2024").person

      travel_to(Time.zone.local(2024, 10, 10)) do
        expect(people_scope).to match_array [started_and_ended_inside_range]
      end
      travel_to(Time.zone.local(2026, 10, 10)) do
        expect(people_scope).to match_array [started_and_ended_inside_range]
      end
    end

    it "excludes not yet active membership" do
      create_role("Mitglied", start_on: "31.12.2024")

      travel_to(Time.zone.local(2024, 10, 10)) do
        expect(people_scope).to be_empty
      end
    end

    describe "range border" do
      it "includes if role starts on begin of range" do
        person = create_role("Mitglied", start_on: "1.7.2024").person
        expect(people_scope).to eq [person]
      end

      it "includes if role starts on end of range" do
        person = create_role("Mitglied", start_on: "30.6.2025").person
        expect(people_scope).to eq [person]
      end
    end
  end

  describe "data_rows" do
    let(:mitglied) { people(:mitglied) }

    let(:row_class) { Data.define(*described_class::ATTRIBUTES) { def to_s = [first_name, last_name].join(" ") } }
    let(:rows) { build.data_rows.map { |r| row_class.new(*r) } }

    def row_for(person) = rows.index_by(&:id).fetch(person.id)

    def build_rows(range_string)
      build(range_string).data_rows.map { |r| row_class.new(*r) }
    end

    it "does not do N+1 queries" do
      tabular = build("1.1.2015-31.12.2015")

      expect_query_count do
        expect(tabular.data_rows).to have(4).items
      end.to eq 3
    end

    describe "common" do
      let(:rows) { build_rows("1.1.2015-31.12.2015") }

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
          url: "http://test.host/groups/380959420/people/600001/history",
          sektion: "SAC Blüemlisalp",
          sac_is_new_entry: "ja",
          sac_is_re_entry: "nein",
          sac_is_section_new_entry: "ja",
          sac_is_section_change: "nein",
          membership_years: 10,
          sac_entry_on: "01.01.2015",
          sektion_entry_on: "01.01.2015",
          terminate_on: nil,
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
        expect(rows.map(&:to_s)).to eq ["Edmund Hillary", "Frieda Norgay", "Nima Norgay", "Tenzing Norgay"]
      end

      it "correctly popluates terminate_on" do
        travel_to(Time.zone.local(2025, 11, 3)) do
          Roles::Termination.new(role: roles(:mitglied), terminate_on: 1.day.from_now).call
          expect(row_for(mitglied).terminate_on).to eq "04.11.2025"
        end
      end
    end

    describe "sac entry specific fields" do
      let(:rows) { build_rows("1.1.2025-31.12.2025") }

      it "marks Stammmitgliedschaft" do
        person = create_role("Mitglied", bluemlisalp, start_on: "10.10.2025").person

        expect(row_for(person).sac_is_new_entry).to eq "ja"
        expect(row_for(person).sac_is_re_entry).to eq "nein"
        expect(row_for(person).sac_is_section_new_entry).to eq "ja"
        expect(row_for(person).sac_is_section_change).to eq "nein"
      end

      it "marks Zusatzmitgliedschaft" do
        person = create_role("Mitglied", matterhorn, start_on: "10.10.2024").person
        create_role("MitgliedZusatzsektion", bluemlisalp, start_on: "10.10.2025", person:)

        expect(row_for(person).sac_is_new_entry).to eq "nein"
        expect(row_for(person).sac_is_re_entry).to eq "nein"
        expect(row_for(person).sac_is_section_new_entry).to eq "ja"
        expect(row_for(person).sac_is_section_change).to eq "nein"
      end

      it "marks reactivated Zusatzmitgliedschaft" do
        person = create_role("Mitglied", matterhorn, start_on: "1.1.2000", end_on: "31.12.2025").person
        create_role("Mitglied", start_on: "1.1.2005", end_on: "31.12.2015").person
        create_role("MitgliedZusatzsektion", start_on: "1.1.2025", end_on: "31.12.2025", person:)
        expect(row_for(person).sac_is_re_entry).to eq "nein"
        expect(row_for(person).sac_is_new_entry).to eq "nein"
        expect(row_for(person).sac_is_section_new_entry).to eq "ja"
        expect(row_for(person).sac_is_section_change).to eq "nein"
      end

      it "marks Sektionswechsel" do
        person = create_role("Mitglied", matterhorn, start_on: "1.1.2000", end_on: "31.12.2024").person
        create_role("Mitglied", bluemlisalp, start_on: "1.1.2025", end_on: "31.12.2025", person:)

        expect(row_for(person).sac_is_new_entry).to eq "nein"
        expect(row_for(person).sac_is_re_entry).to eq "nein"
        expect(row_for(person).sac_is_section_new_entry).to eq "ja"
        expect(row_for(person).sac_is_section_change).to eq "ja"
      end

      describe "reentry" do
        it "marks reactivated membership from former stammmitgliedschaft" do
          person = create_role("Mitglied", start_on: "1.1.2000", end_on: "31.12.2000").person
          create_role("Mitglied", start_on: "1.1.2025", end_on: "31.12.2025", person:)

          expect(row_for(person).sac_is_re_entry).to eq "ja"
          expect(row_for(person).sac_is_new_entry).to eq "nein"
          expect(row_for(person).sac_is_section_new_entry).to eq "nein"
          expect(row_for(person).sac_is_section_change).to eq "nein"
        end

        it "does mark if role outside and multiple roles inside range exist" do
          person = create_role("Mitglied", start_on: "1.1.2000", end_on: "31.12.2000").person
          create_role("Mitglied", start_on: "1.1.2025", end_on: "1.3.2025", person:)
          create_role("Mitglied", start_on: "2.3.2025", end_on: "31.12.2025", person:)
          expect(row_for(person).sac_is_re_entry).to eq "ja"
        end

        it "does mark mark if all roles are in range" do
          person = create_role("Mitglied", start_on: "1.1.2025", end_on: "1.3.2025").person
          create_role("Mitglied", start_on: "2.3.2025", end_on: "30.9.2025", person:)
          create_role("Mitglied", start_on: "1.10.2025", end_on: "31.12.2025", person:)
          expect(row_for(person).sac_is_new_entry).to eq "ja"
          expect(row_for(person).sac_is_re_entry).to eq "nein"
          expect(row_for(person).sac_is_section_new_entry).to eq "ja"
          expect(row_for(person).sac_is_section_change).to eq "nein"
        end
      end
    end
  end
end
