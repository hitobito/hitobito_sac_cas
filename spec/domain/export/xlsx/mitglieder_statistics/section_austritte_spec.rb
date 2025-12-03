# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Xlsx::MitgliederStatistics::SectionAustritte do
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:matterhorn) { groups(:matterhorn_mitglieder) }

  let(:section) { described_class.new(group, range) }

  let(:reasons) do
    TerminationReason.all.sort_by(&:text)
  end

  def create_role_plain(type = "Mitglied", **attrs)
    Fabricate(
      "Group::SektionsMitglieder::#{type}",
      attrs.reverse_merge(group:, beitragskategorie: :adult, start_on: "2015-01-01")
    )
  end

  def create_role(type = "Mitglied", **attrs)
    create_role_plain(type, **attrs.merge(end_on: Date.current.end_of_year)).tap do |role|
      if attrs[:end_on]
        Roles::Termination.new(role:, terminate_on: attrs[:end_on], validate_terminate_on: false).call
      end
    end
  end

  describe "calculations" do
    let(:range) { Date.new(2024, 1, 1)..Date.new(2024, 12, 31) }

    before do
      create_role(end_on: "2023-12-31", termination_reason: reasons.first)
      create_role(end_on: "2024-03-01", termination_reason: reasons.first)
      create_role(end_on: "2024-12-31", termination_reason: reasons.first)
      create_role(end_on: "2024-04-01")

      # non-terminated roles are ignored
      create_role_plain(end_on: "2024-12-31")

      # non-member roles are ignored
      Fabricate("Group::SektionsMitglieder::Leserecht",
        group:,
        start_on: "2015-01-01",
        end_on: "2024-06-30")
    end

    it "calculates total" do
      expect(section.total).to eq(3)
    end

    it "groups by termination reasons" do
      expect(section.counts(:termination_reason)).to eq(
        reasons.each_with_index.each_with_object({nil => 1}) do |(reason, index), hash|
          hash[reason.text] = ((index == 0) ? 2 : 0)
        end
      )
    end
  end

  describe "#scope" do
    let(:range) { Date.new(2024, 7, 1)..Date.new(2025, 6, 30) }

    subject(:scope) { section.send(:scope) }

    def scope_for(range_string)
      from, to = range_string.split("-").map { |s| Date.parse(s) }
      described_class.new(group, from..to).send(:scope)
    end

    it "testing most common cases" do
      stammsektion = create_role(end_on: "10.7.2024")

      zusatzsektion_person = create_role(group: matterhorn, start_on: "3.2.2000").person
      zusatzsektion = create_role("MitgliedZusatzsektion", end_on: "30.6.2025", person: zusatzsektion_person)

      stammsektions_wechsel = create_role(start_on: "3.2.2000", end_on: "30.6.2025")
      create_role(group: matterhorn, start_on: "1.7.2025", person: stammsektions_wechsel.person)

      bk_change_person = create_role(start_on: "1.1.2024", end_on: "31.12.2024").person
      bk_change_person.update!(sac_family_main_person: true)
      bk_change = create_role(start_on: "1.1.2025", end_on: "30.12.2025", beitragskategorie: :family,
        person: bk_change_person)

      sac_re_entry = create_role("Mitglied", start_on: "3.2.2000", end_on: "1.6.2025")
      create_role(group: matterhorn, start_on: "1.9.2025", person: sac_re_entry.person)

      section_re_entry_person = create_role(group: matterhorn, start_on: "3.2.2000").person
      section_re_entry = create_role("MitgliedZusatzsektion", start_on: "30.6.2010", end_on: "30.7.2024",
        person: section_re_entry_person)
      create_role("MitgliedZusatzsektion", start_on: "1.7.2025", person: section_re_entry_person)

      prolongation = create_role(end_on: "30.6.2025")
      create_role(start_on: "1.7.2025", person: prolongation.person)

      multi_person = create_role(end_on: "31.8.2024").person
      create_role(start_on: "1.9.2024", end_on: "31.12.2024", person: multi_person)
      multi = create_role(start_on: "1.1.2025", end_on: "31.3.2025", person: multi_person)

      with_gap1 = create_role("Mitglied", end_on: "9.9.2024")
      create_role(start_on: "1.1.2025", person: with_gap1.person)

      # not part of scope
      too_early = create_role(end_on: "30.6.2024") # too early
      create_role("Leserecht", end_on: "1.1.2025") # outside of roles scope

      too_new_person = create_role("Mitglied", group: matterhorn).person
      _too_new = create_role("MitgliedZusatzsektion", end_on: "1.7.2025", person: too_new_person)

      too_old = create_role(end_on: "31.12.2025")
      # outside of group
      create_role("MitgliedZusatzsektion", group: matterhorn, end_on: "30.6.2025", person: too_old.person)

      # non-terminated role with end on
      create_role_plain(end_on: "2024-12-31")
      create_role_plain(end_on: "2025-12-31")

      expect(scope).to match_array [
        stammsektion,
        zusatzsektion,
        stammsektions_wechsel,
        sac_re_entry,
        section_re_entry,
        multi
      ]

      expect(section.total).to eq(6)

      expect(section.counts(:language)).to eq(
        {"de" => 6, "fr" => 0, "it" => 0, "en" => 0}
      )

      expect(section.counts(:age)).to eq(
        {"6-17" => 0, "18-22" => 0, "23-35" => 6, "36-50" => 0, "51-60" => 0, "61+" => 0}
      )

      expect(section.counts(:beitragskategorie)).to eq(
        {"adult" => 6, "family_main" => 0, "family_adult" => 0, "family_child" => 0, "youth" => 0}
      )

      expect(scope_for("1.8.2025-30.12.2025")).to eq [bk_change]
      expect(scope_for("30.6.2024-30.6.2024")).to match_array [too_early]
      expect(scope_for("1.1.2025-1.3.2025")).to be_empty
      expect(scope_for("1.9.2024-30.9.2024")).to eq [with_gap1]
      expect(scope_for("1.1.2026-31.12.2026")).to be_empty
    end

    it "includes memberships with gap but excludes consecutive memberships" do
      prev_year1 = create_role(start_on: "1.1.2023", end_on: "30.6.2023")
      prev_year2 = create_role(start_on: "1.7.2023", end_on: "30.4.2024", person: prev_year1.person)
      prev_year3 = create_role(start_on: "1.7.2024", end_on: "31.8.2024", person: prev_year1.person)

      same_year1 = create_role(start_on: "1.1.2024", end_on: "30.6.2024")
      same_year2 = create_role(start_on: "1.7.2024", end_on: "31.8.2024", person: same_year1.person)
      same_year3 = create_role(start_on: "1.11.2024", end_on: "31.12.2024", person: same_year1.person)

      same_year_with_gap1 = create_role(start_on: "1.1.2024", end_on: "29.6.2024")
      same_year_with_gap2 = create_role(start_on: "1.7.2024", end_on: "31.8.2024", person: same_year_with_gap1.person)
      same_year_with_gap3 = create_role(start_on: "1.11.2024", end_on: "30.6.2025", person: same_year_with_gap1.person)

      expect(scope_for("10.10.2024-1.2.2025")).to match_array [same_year3]
      expect(scope_for("1.6.2025-10.7.2025")).to match_array [same_year_with_gap3]
      expect(scope_for("1.3.2023-30.9.2023")).to be_empty
      expect(scope_for("1.4.2024-30.5.2024")).to match_array [prev_year2]
      expect(scope_for("1.4.2023-30.6.2024")).to match_array [prev_year2, same_year_with_gap1]
      expect(scope_for("1.3.2024-30.9.2024")).to match_array [prev_year3, same_year2, same_year_with_gap2]
      expect(scope_for("1.7.2024-30.7.2024")).to be_empty # ap started to early / late, others consecutive
      expect(scope_for("1.1.2024-30.6.2024")).to match_array [prev_year2, same_year_with_gap1]
    end

    it "includes membership with multiple roles if all end within range" do
      # consecutive roles before austritt => counts as austritt
      role = create_role(end_on: "31.12.2024")
      person = role.person
      create_role(start_on: "1.1.2025", end_on: "28.2.2025", person:)
      consecutive = create_role(start_on: "1.3.2025", end_on: "30.6.2025", person:)

      # austritt after period => does not count as austritt
      after_person = create_role(end_on: "30.8.2024").person
      create_role(start_on: "1.9.2024", end_on: "28.2.2025", person: after_person)
      create_role(start_on: "1.3.2025", end_on: "1.7.2025", person: after_person)

      # eintritt after period => counts as austritt
      previous_person = create_role(start_on: "1.7.2022", end_on: "31.12.2024").person
      previous = create_role(start_on: "1.1.2025", end_on: "28.2.2025", person: previous_person)
      create_role(start_on: "1.7.2025", person: previous_person)

      # eintritt in period => does not count as austritt
      inside_person = create_role(start_on: "1.7.2022", end_on: "31.12.2024").person
      create_role(start_on: "1.1.2025", end_on: "28.2.2025", person: inside_person)
      create_role(start_on: "30.6.2025", person: inside_person)

      expect(scope).to match_array [consecutive, previous]
    end

    it "includes membership with gap in wider but excludes in narrower range" do
      role1 = create_role(start_on: "1.7.2000", end_on: "1.3.2022")
      role2 = create_role(start_on: "1.7.2022", end_on: "31.12.2024", person: role1.person)

      expect(scope_for("1.1.2022-31.12.2022")).to be_empty # continuation
      expect(scope_for("1.1.2022-30.6.2022")).to eq [role1]
      expect(scope_for("1.6.2022-1.9.2022")).to be_empty
      expect(scope_for("1.1.2024-1.12.2024")).to be_empty
      expect(scope_for("1.1.2024-31.12.2024")).to eq [role2]
    end

    it "includes not yet terminated membership" do
      role = create_role(end_on: "31.12.2024")

      travel_to(Time.zone.local(2024, 10, 10)) do
        expect(scope).to eq [role]
      end
    end

    describe "range border" do
      it "does not include if role ends a day before range" do
        create_role(end_on: "30.6.2024")
        expect(scope).to be_empty
      end

      it "includes if role ends on begin of range" do
        role = create_role(end_on: "1.7.2024")
        expect(scope).to eq [role]
      end

      it "includes if role ends on end of range" do
        role = create_role(end_on: "30.6.2025")
        expect(scope).to eq [role]
      end

      it "does not include if role ends a day after range" do
        create_role(end_on: "1.7.2025")
        expect(scope).to be_empty
      end
    end
  end
end
