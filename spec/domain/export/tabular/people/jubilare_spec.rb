# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::People::Jubilare do
  let(:user) { people(:admin) }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:reference_date) { Date.new(2025, 10, 1) }
  let(:membership_years) { nil }

  subject(:tabular) { described_class.new(group, user.id, reference_date, membership_years) }

  describe "#data_rows" do
    it "does not do N+1 queries" do
      expect_query_count { tabular.data_rows.to_a }.to eq 7
    end

    it "contains all attributes" do
      people(:mitglied).update!(
        address_care_of: "c/o Mami u Papi",
        postbox: "Postfach 1",
        gender: "m",
        birthday: "21.04.1972"
      )
      people(:mitglied).phone_numbers.create!(label: "landline", number: "031 333 44 55")
      people(:mitglied).phone_numbers.create!(label: "mobile", number: "079 333 44 55")
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
        group: groups(:matterhorn_mitglieder), person: people(:abonnent), start_on: "2.10.2015")
      Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
        group: groups(:bluemlisalp_mitglieder), person: people(:abonnent), start_on: "15.3.2021")
      Fabricate(Group::SektionsMitglieder::Ehrenmitglied.sti_name,
        group: groups(:bluemlisalp_mitglieder),
        person: people(:abonnent),
        start_on: "15.3.2021",
        end_on: Date.current.end_of_year)
      Fabricate(Group::SektionsMitglieder::Beguenstigt.sti_name,
        group: groups(:bluemlisalp_mitglieder),
        person: people(:abonnent),
        start_on: "15.3.2021",
        end_on: "31.12.2023")

      rows = tabular.data_rows.to_a
      expect(rows.first).to eq([
        600001,
        "http://test.host/de/groups/#{group.id}/people/600001/history",
        "SAC Blüemlisalp",
        10,
        "01.01.2015",
        "01.01.2015",
        nil,
        "Stammsektion",
        "Einzel",
        "nein",
        "nein",
        "Hillary",
        "Edmund",
        "männlich",
        "21.04.1972",
        "Digital",
        "e.hillary@hitobito.example.com",
        "+41 79 333 44 55",
        "+41 31 333 44 55",
        "Postfach 1",
        "Ophovenerstrasse",
        "79a",
        "c/o Mami u Papi",
        "2843",
        "Neu Carlscheid",
        "CH"
      ])

      expect(rows.second).to eq([
        600_005,
        "http://test.host/de/groups/#{group.id}/people/600005/history",
        "SAC Blüemlisalp",
        9,
        "02.10.2015",
        "15.03.2021",
        nil,
        "Zusatzsektion",
        "Einzel",
        "ja",
        "nein",
        "Leseratte",
        "Magazina",
        "weiblich",
        "12.06.1993",
        "Digital",
        "magazina.l@hitobito.example.com",
        nil,
        nil,
        nil,
        "Ophovenerstrasse",
        "79a",
        nil,
        "2843",
        "Neu Carlscheid",
        nil
      ])
    end
  end

  describe "#people_scope" do
    let(:list) { tabular.people_scope }

    it "all mitglieder are included" do
      expect(list).to eq([
        roles(:mitglied).person,
        roles(:familienmitglied2).person,
        roles(:familienmitglied_kind).person,
        roles(:familienmitglied).person
      ])

      expect(list.map(&:membership_years)).to eq([10, 10, 10, 10])
    end

    it "zusatzsektion mitglieder are included" do
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
        group: groups(:matterhorn_mitglieder), person: people(:abonnent), start_on: "2.10.2016")
      Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
        group: groups(:bluemlisalp_mitglieder), person: people(:abonnent), start_on: "15.03.2021")

      person = list.second
      expect(person).to eq(people(:abonnent))
      expect(person.membership_years).to eq(8)
    end

    it "former mitglieder are included if active on reference date" do
      roles(:mitglied).update!(end_on: 1.day.ago)
      expect(list).to contain_exactly(
        roles(:mitglied).person,
        roles(:familienmitglied).person,
        roles(:familienmitglied2).person,
        roles(:familienmitglied_kind).person
      )
    end

    it "former mitglieder are excluded if ended before reference_date" do
      roles(:mitglied).update!(end_on: reference_date - 1.day)
      expect(list).to contain_exactly(
        roles(:familienmitglied).person,
        roles(:familienmitglied2).person,
        roles(:familienmitglied_kind).person
      )
    end

    it "mitglieder of descendent layer are not included" do
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
        group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
        person: people(:abonnent))
      expect(list).not_to include people(:abonnent)
    end

    context "filter by membership_years" do
      let(:membership_years) { 5 }

      it "includes only people with matching years" do
        roles(:mitglied).update!(start_on: "1.10.2020")
        expect(list).to contain_exactly(roles(:mitglied).person)
      end
    end

    context "future reference date" do
      let(:start_year) { 2015 }
      let(:current_year) { Date.current.year }
      let(:reference_date) { Date.new(current_year + 2, 10, 1) }
      let(:years) { (current_year - start_year) }
      let!(:terminated_role) do
        terminated_role = Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
          group: groups(:bluemlisalp_mitglieder),
          person: people(:abonnent),
          start_on: "2.10.2016",
          end_on: "31.12.#{current_year}")

        terminated_role.write_attribute(:terminated, true)
        terminated_role.save!
        terminated_role
      end

      it "counts membership years correctly for terminated roles" do
        expect(list).to include(terminated_role.person)
        # list query contains years without offset
        expect(list.map(&:membership_years)).to eq([years, years - 2, years, years, years])

        # data rows contain years with offset
        rows = tabular.data_rows.to_a
        expect(rows.map(&:fourth)).to eq([years + 2, years, years + 2, years + 2, years + 2])
      end

      context "filter by membership_years" do
        let(:membership_years) { years }

        it "includes only people with matching years" do
          expect(list).to eq([terminated_role.person])
          expect(list.first.membership_years).to eq(years - 2)
          expect(tabular.send(:membership_years_offset)).to eq(2)
        end
      end
    end
  end
end
