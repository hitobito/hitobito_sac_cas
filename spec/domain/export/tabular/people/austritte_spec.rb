# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::People::Austritte do
  let(:user) { people(:admin) }
  let(:bluemlisalp) { groups(:bluemlisalp_mitglieder) }
  let(:matterhorn) { groups(:matterhorn_mitglieder) }

  def create_role_plain(type, **attrs)
    Fabricate("Group::SektionsMitglieder::#{type}", attrs.reverse_merge(group: bluemlisalp))
  end

  def create_role(type = "Mitglied", **attrs)
    end_on = [attrs[:start_on].to_date, Date.current].max.end_of_year
    create_role_plain(type, **attrs.merge(end_on:)).tap do |role|
      terminate_role(role, **attrs) if attrs[:end_on]
    end
  end

  def terminate_role(role, **attrs)
    Roles::Termination.new(role:, terminate_on: attrs[:end_on], validate_terminate_on: false).call
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
      :sac_is_terminated,
      :sac_is_section_change,
      :end_on,
      :termination_reason,
      :data_retention_consent,
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
      stammsektions_austritt = create_role("Mitglied", start_on: "10.7.2024", end_on: "31.12.2024").person

      zusatzsektions_austritt = create_role("Mitglied", group: matterhorn, start_on: "10.7.2024").person
      create_role("MitgliedZusatzsektion", start_on: "10.7.2024", end_on: "30.06.2025", person: zusatzsektions_austritt)

      stammsektions_wechsel = create_role("Mitglied", start_on: "3.2.2000", end_on: "31.12.2024").person
      create_role("Mitglied", group: matterhorn, start_on: "1.1.2025", person: stammsektions_wechsel)

      stammsektions_swap = create_role("Mitglied", start_on: "3.2.2000", end_on: "31.12.2024").person
      create_role("Mitglied", group: matterhorn, start_on: "1.1.2025", person: stammsektions_swap)
      create_role("MitgliedZusatzsektion", start_on: "1.1.2025", person: stammsektions_swap)

      # terminated=false (e.g. invoice not paid)
      past_not_terminated = create_role_plain("Mitglied", start_on: "10.7.2024", end_on: "31.03.2025").person
      # terminated=false because role was not prolonged yet
      _future_not_terminated = create_role_plain("Mitglied", start_on: "10.7.2024", end_on: "30.06.2025").person

      # not part of scope
      too_old = create_role("Mitglied", start_on: "1.1.2024", end_on: "30.6.2024").person # too old
      too_new = create_role("Mitglied", start_on: "30.6.2024", end_on: "12.12.2025").person # too new

      with_membership_later_on = create_role("Mitglied", start_on: "1.1.2024", end_on: "10.12.2024").person
      create_role("Mitglied", person: with_membership_later_on, start_on: "1.1.2026", end_on: "31.12.2026")

      travel_to(Time.zone.local(2025, 6, 30)) do
        expect(people_scope.map(&:to_s)).to match_array [
          stammsektions_austritt,
          zusatzsektions_austritt,
          stammsektions_wechsel,
          with_membership_later_on,
          past_not_terminated
        ].map(&:to_s)

        expect(build("1.1.2024-30.6.2024").people_scope).to match_array [too_old]
        expect(build("1.7.2025-12.12.2025").people_scope).to match_array [too_new]
      end
    end

    it "excludes ended membership older than a year" do
      started_and_ended_inside_range = create_role("Mitglied", start_on: "1.7.2024", end_on: "1.8.2024").person

      travel_to(Time.zone.local(2024, 10, 10)) do
        expect(build.people_scope).to match_array [started_and_ended_inside_range]
      end

      travel_to(Time.zone.local(2026, 10, 10)) do
        expect(build.people_scope).to be_empty # missing as ended role no longer readable
      end
    end

    describe "range border" do
      it "includes if role ends on begin of range" do
        person = create_role("Mitglied", start_on: "1.1.2024", end_on: "1.7.2024").person
        travel_to(Time.zone.local(2025, 6, 30)) do
          expect(people_scope).to eq [person]
        end
      end

      it "includes if role ends on end of range" do
        person = create_role("Mitglied", start_on: "1.1.2025", end_on: "30.6.2025").person
        travel_to(Time.zone.local(2025, 6, 30)) do
          expect(people_scope).to eq [person]
        end
      end
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
      create_role("Mitglied", start_on: "10.7.2013", end_on: "31.12.2014")
      create_role("Mitglied", start_on: "10.7.2013", end_on: "11.2.2014")
      create_role("Mitglied", start_on: "10.7.2013", end_on: "1.1.2014")
      create_role("Mitglied", start_on: "10.7.2013", end_on: "11.2.2014")
      create_role("Mitglied", start_on: "10.7.2013", end_on: "1.1.2014")
      tabular = build("1.1.2014-31.12.2014")

      travel_to(Time.zone.local(2014, 6, 30)) do
        expect_query_count do
          expect(tabular.data_rows).to have(5).items
        end.to eq(5)
      end
    end

    describe "common" do
      let(:rows) { build_rows("1.1.2014-31.12.2014") }

      before do
        travel_to(Time.zone.local(2014, 6, 30)) do
          role1 = create_role("Mitglied", person: people(:mitglied), start_on: "10.7.2013", end_on: "31.10.2014")
          create_role("Mitglied", person: people(:familienmitglied), start_on: "10.7.2013", end_on: "11.2.2014").person
          create_role("Mitglied", person: people(:familienmitglied2), start_on: "10.7.2013", end_on: "1.1.2014").person

          Roles::Termination.new(role: role1, terminate_on: "31.10.2014", validate_terminate_on: false).call
        end
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
          sac_is_terminated: "nein",
          sac_is_section_change: "nein",
          end_on: "31.10.2014",
          termination_reason: "ADM",
          data_retention_consent: "nein",
          type: "Stammsektion",
          beitragskategorie: "Jugend",
          membership_years: 0,
          sac_entry_on: "10.07.2013",
          sektion_entry_on: "10.07.2013",
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
        travel_to(Time.zone.local(2014, 6, 30)) do
          expect(rows.map(&:to_s)).to eq ["Edmund Hillary", "Frieda Norgay", "Tenzing Norgay"]
        end
      end

      it "correctly popluates terminate_on" do
        travel_to(Time.zone.local(2025, 11, 3)) do
          Roles::Termination.new(role: roles(:mitglied), terminate_on: 1.day.from_now).call
          expect(row_for(mitglied, bluemlisalp, "1.1.2015-31.12.2025").end_on).to eq "04.11.2025"
        end
      end
    end

    describe "sac termination specific fields" do
      let(:rows) { build_rows("1.1.2025-31.12.2025") }

      it "marks termination" do
        role = create_role("Mitglied", start_on: "10.10.2025", end_on: "12.11.2025",
          termination_reason: termination_reasons(:moved))

        travel_to(Time.zone.local(2025, 6, 30)) do
          row = row_for(role.person)
          expect(row.sac_is_terminated).to eq "ja"
          expect(row.end_on).to eq "12.11.2025"
          expect(row.termination_reason).to eq "Umgezogen"
        end
      end

      it "marks termination at end of range with multiple roles" do
        person = create_role("Mitglied", start_on: "10.1.2020", end_on: "09.10.2025").person
        role = create_role("Mitglied", start_on: "10.10.2025", end_on: "31.12.2025",
          termination_reason: termination_reasons(:moved), person: person)

        travel_to(Time.zone.local(2025, 6, 30)) do
          row = row_for(role.person)
          expect(row.sac_is_terminated).to eq "ja"
          expect(row.end_on).to eq "31.12.2025"
          expect(row.termination_reason).to eq "Umgezogen"
        end
      end

      it "marks section change" do
        stammsektions_wechsel = create_role("Mitglied", start_on: "3.2.2000", end_on: "31.12.2025").person
        create_role("Mitglied", group: matterhorn, start_on: "1.1.2026", end_on: "1.1.2027",
          person: stammsektions_wechsel)

        travel_to(Time.zone.local(2025, 6, 30)) do
          row = row_for(stammsektions_wechsel)
          expect(row.sac_is_section_change).to eq "ja"
          expect(row.sac_is_terminated).to eq "nein"
        end
      end

      it "marks terminating zusatzsektion" do
        person = create_role("Mitglied", group: matterhorn, start_on: "1.1.2020").person
        create_role("MitgliedZusatzsektion", start_on: "1.1.2020", end_on: "31.07.2025", person: person)

        travel_to(Time.zone.local(2025, 6, 30)) do
          row = row_for(person)
          expect(row.end_on).to eq "31.07.2025"
          expect(row.sac_is_section_change).to eq "nein"
          expect(row.sac_is_terminated).to eq "nein"
        end
      end

      it "marks terminating zusatzsektion with terminating stammsektion" do
        travel_to(Time.zone.local(2025, 6, 30)) do
          person = create_role("Mitglied", group: matterhorn, start_on: "1.1.2020", end_on: "31.12.2025").person
          create_role("MitgliedZusatzsektion", start_on: "1.1.2020", end_on: "31.12.2025", person: person)

          row = row_for(person)
          expect(row.end_on).to eq "31.12.2025"
          expect(row.sac_is_section_change).to eq "nein"
          expect(row.sac_is_terminated).to eq "ja"
        end
      end

      it "marks data retention consent" do
        person = create_role("Mitglied", start_on: "3.2.2000", end_on: "31.12.2025").person
        Fabricate(Group::AboBasicLogin::BasicLogin.sti_name.to_sym, person: person, group: groups(:abo_basic_login))

        travel_to(Time.zone.local(2025, 6, 30)) do
          expect(row_for(person).data_retention_consent).to eq "ja"
        end
      end
    end
  end
end
