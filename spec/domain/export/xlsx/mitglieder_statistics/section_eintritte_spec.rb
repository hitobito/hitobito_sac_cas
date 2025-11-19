# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Xlsx::MitgliederStatistics::SectionEintritte do
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:matterhorn) { groups(:matterhorn_mitglieder) }

  let(:section) { described_class.new(group, range) }

  let(:reasons) do
    SelfRegistrationReason.all.sort_by(&:text)
  end

  def create_role(type = "Mitglied", **attrs)
    Fabricate(
      "Group::SektionsMitglieder::#{type}",
      attrs.reverse_merge(group:, beitragskategorie: :adult)
    )
  end

  describe "calculations" do
    let(:range) { Date.new(2024, 1, 1)..Date.new(2024, 12, 31) }

    before do
      # reasons are readonly, use workaround to set them
      p1 = create_role(start_on: "2023-12-31").person
      Person.where(id: p1.id).update_all(self_registration_reason_id: reasons.first.id)
      p2 = create_role(start_on: "2024-03-01").person
      Person.where(id: p2.id).update_all(self_registration_reason_id: reasons.second.id)
      p3 = create_role(start_on: "2024-12-31").person
      Person.where(id: p3.id).update_all(self_registration_reason_id: reasons.third.id)
      p4 = create_role(start_on: "2024-04-01").person
      Person.where(id: p4.id).update_all(self_registration_reason_custom_text: "Es gfaut mir so guet")

      Fabricate("Group::SektionsMitglieder::Leserecht", group:, start_on: "2024-06-01") # non-member roles are ignored
    end

    it "calculates total" do
      expect(section.total).to eq(3)
    end

    it "groups by self registration reasons" do
      expect(section.counts(:self_registration_reason)).to eq(
        reasons.each_with_index.each_with_object({nil => 1}) do |(reason, index), hash|
          hash[reason.text] = index.in?([1, 2]) ? 1 : 0
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
      stammsektion = create_role(start_on: "10.7.2024")

      zusatzsektion_person = create_role(group: matterhorn, start_on: "3.2.2000").person
      zusatzsektion = create_role("MitgliedZusatzsektion", start_on: "30.6.2025", person: zusatzsektion_person)

      stammsektions_wechsel_person = create_role(group: matterhorn, start_on: "3.2.2000", end_on: "30.6.2024").person
      stammsektions_wechsel = create_role(start_on: "1.7.2024", person: stammsektions_wechsel_person)

      bk_change = create_role(start_on: "1.1.2024", end_on: "31.12.2024")
      bk_change.person.update!(sac_family_main_person: true)
      create_role(start_on: "1.1.2025", beitragskategorie: :family, person: bk_change.person)

      sac_re_entry_person = create_role("Mitglied", group: matterhorn, start_on: "3.2.2000", end_on: "30.6.2010").person
      sac_re_entry = create_role(start_on: "30.6.2025", person: sac_re_entry_person)

      section_re_entry_person = create_role(group: matterhorn, start_on: "3.2.2000").person
      create_role("MitgliedZusatzsektion", start_on: "30.6.2010", end_on: "30.6.2020", person: section_re_entry_person)
      section_re_entry = create_role("MitgliedZusatzsektion", start_on: "10.7.2024", person: section_re_entry_person)

      prolongation = create_role(start_on: "1.1.2020", end_on: "30.6.2024")
      create_role(start_on: "1.7.2024", person: prolongation.person)

      multi = create_role(start_on: "1.9.2024", end_on: "31.12.2024")
      create_role(start_on: "1.1.2025", end_on: "31.3.2025", person: multi.person)
      create_role(start_on: "1.4.2025", person: multi.person)

      with_gap1 = create_role("Mitglied", start_on: "30.6.2024", end_on: "31.12.2024")
      with_gap2 = create_role(start_on: "3.3.2025", person: with_gap1.person)

      # not part of scope
      create_role(start_on: "1.7.2025") # too new
      create_role("Leserecht", start_on: "1.1.2025") # outside of roles scope

      too_new_person = create_role("Mitglied", group: matterhorn, start_on: "1.1.2025").person
      _too_new = create_role("MitgliedZusatzsektion", start_on: "1.7.2025", person: too_new_person)

      too_old = create_role(start_on: "30.6.2024")
      # outside of group
      create_role("MitgliedZusatzsektion", group: matterhorn, start_on: "30.6.2025", person: too_old.person)

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
        {"6-17" => 0, "18-22" => 0, "23-35" => 6, "36-50" => 0, "51-60" => 0, "61-" => 0}
      )

      expect(section.counts(:beitragskategorie)).to eq(
        {"adult" => 6, "family_main" => 0, "family_adult" => 0, "family_child" => 0, "youth" => 0}
      )

      expect(scope_for("1.1.2024-29.6.2024")).to eq [bk_change]
      expect(scope_for("30.6.2024-30.6.2024")).to match_array [with_gap1, too_old]
      expect(scope_for("1.1.2025-1.3.2025")).to be_empty
      expect(scope_for("1.3.2025-1.5.2025")).to eq [with_gap2]
      expect(scope_for("1.1.2026-31.12.2026")).to be_empty
    end

    it "includes memberships with gap but excludes consecutive memberships" do
      prev_year1 = create_role(start_on: "1.1.2023", end_on: "1.2.2023")
      prev_year2 = create_role(start_on: "1.10.2023", end_on: "30.6.2024", person: prev_year1.person)
      _prev_year3 = create_role(start_on: "1.7.2024", person: prev_year1.person)

      same_year1 = create_role(start_on: "1.1.2024", end_on: "1.2.2024")
      same_year2 = create_role(start_on: "1.4.2024", end_on: "30.6.2024", person: same_year1.person)
      _same_year3 = create_role(start_on: "1.7.2024", person: same_year1.person)

      same_year_with_gap1 = create_role(start_on: "1.1.2024", end_on: "29.2.2024")
      same_year_with_gap2 = create_role(start_on: "1.4.2024", end_on: "29.6.2024", person: same_year_with_gap1.person)
      same_year_with_gap3 = create_role(start_on: "1.7.2024", person: same_year_with_gap1.person)

      expect(scope_for("10.10.2022-1.10.2023")).to eq [prev_year1]
      expect(scope_for("1.1.2023-10.1.2023")).to eq [prev_year1]
      expect(scope_for("1.3.2023-30.9.2023")).to be_empty
      expect(scope_for("1.4.2023-30.10.2023")).to eq [prev_year2]
      expect(scope_for("1.6.2023-30.10.2023")).to eq [prev_year2]
      expect(scope_for("1.3.2024-30.6.2025")).to match_array [same_year2, same_year_with_gap2]
      expect(scope_for("1.6.2024-30.6.2025")).to be_empty # ap started to early / late, others consecutive
      expect(scope_for("1.7.2024-30.6.2025")).to match_array [same_year_with_gap3]
    end

    it "includes membership with multiple roles if all start within range" do
      # consecutive roles after eintritt => counts as eintritt
      role = create_role(start_on: "1.7.2024", end_on: "31.12.2024")
      person = role.person
      create_role(start_on: "1.1.2025", end_on: "28.2.2025", person:)
      create_role(start_on: "1.3.2025", person:)

      # eintritt before period => does not count as eintritt
      before_person = create_role(start_on: "30.6.2024", end_on: "30.8.2024").person
      create_role(start_on: "1.9.2024", end_on: "28.2.2025", person: before_person)
      create_role(start_on: "1.3.2025", person: before_person)

      # austritt before period => counts as eintritt
      previous_person = create_role(start_on: "1.7.2022", end_on: "30.6.2024").person
      previous = create_role(start_on: "1.1.2025", end_on: "28.2.2025", person: previous_person)
      create_role(start_on: "1.3.2025", person: previous_person)

      # austritt in period => does not count as eintritt
      inside_person = create_role(start_on: "1.7.2022", end_on: "1.7.2024").person
      create_role(start_on: "1.1.2025", end_on: "28.2.2025", person: inside_person)
      create_role(start_on: "1.3.2025", person: inside_person)

      expect(scope).to match_array [role, previous]
    end

    it "includes membership with gap in wider but excludes in narrower range" do
      role1 = create_role(start_on: "1.7.2000", end_on: "1.3.2025")
      role2 = create_role(start_on: "1.7.2025", person: role1.person)

      expect(scope_for("1.1.2025-31.12.2025")).to be_empty # continuation
      expect(scope_for("1.7.2025-31.12.2025")).to eq [role2]
      expect(scope_for("1.1.2025-1.5.2025")).to be_empty
      expect(scope_for("1.1.2000-1.6.2000")).to be_empty
      expect(scope_for("1.1.2000-1.1.2001")).to eq [role1]
    end

    it "includes not yet active membership" do
      role = create_role(start_on: "31.12.2024")

      travel_to(Time.zone.local(2024, 10, 10)) do
        expect(scope).to eq [role]
      end
    end

    describe "range border" do
      it "does not include if role starts a day before range" do
        create_role(start_on: "30.6.2024")
        expect(scope).to be_empty
      end

      it "includes if role starts on begin of range" do
        role = create_role(start_on: "1.7.2024")
        expect(scope).to eq [role]
      end

      it "includes if role starts on end of range" do
        role = create_role(start_on: "30.6.2025")
        expect(scope).to eq [role]
      end

      it "does not include if role starts a day after range" do
        create_role(start_on: "1.7.2025")
        expect(scope).to be_empty
      end
    end
  end
end
