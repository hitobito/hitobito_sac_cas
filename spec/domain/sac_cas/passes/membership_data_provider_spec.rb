# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SacCas::Passes::MembershipDataProvider do
  let(:pass_definition) { pass_definitions(:sac_membership) }
  let(:person) { people(:mitglied) }
  let(:pass) { Fabricate(:pass, person: person, pass_definition: pass_definition) }

  subject { described_class.new(pass) }

  describe "#member_number" do
    it "returns the persons membership number" do
      expect(subject.member_number).to eq(person.membership_number)
    end
  end

  describe "#extra_google_text_modules" do
    it "includes stammsektion module" do
      modules = subject.extra_google_text_modules
      stammsektion = modules.find { |m| m[:header] == I18n.t("passes.sac_membership.section") }
      expect(stammsektion).to be_present
      expect(stammsektion[:body]).to eq(person.primary_group.layer_group.name)
    end

    it "includes zusatzsektionen module when person has additional sections" do
      modules = subject.extra_google_text_modules
      additional = modules.find { |m| m[:header] == I18n.t("passes.sac_membership.additional_sections") }
      expect(additional).to be_present
      expect(additional[:body]).to include("SAC Matterhorn")
    end

    it "omits zusatzsektionen module when person has no additional sections" do
      person.roles.where(type: Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name).destroy_all
      modules = subject.extra_google_text_modules
      additional = modules.find { |m| m[:header] == I18n.t("passes.sac_membership.additional_sections") }
      expect(additional).to be_nil
    end

    it "includes tour guide module when person is active tour guide" do
      person.qualifications.create!(
        qualification_kind: qualification_kinds(:ski_leader),
        start_at: 1.month.ago
      )
      person.roles.create!(
        type: Group::SektionsTourenUndKurse::Tourenleiter.sti_name,
        group: groups(:matterhorn_touren_und_kurse)
      )
      modules = subject.extra_google_text_modules
      tour_guide = modules.find { |m| m[:header] == I18n.t("passes.sac_membership.tour_guide") }
      expect(tour_guide).to be_present
      expect(tour_guide[:body]).to eq(I18n.t("passes.sac_membership.tour_guide_active"))
    end

    it "omits tour guide module when person is not a tour guide" do
      modules = subject.extra_google_text_modules
      tour_guide = modules.find { |m| m[:header] == I18n.t("passes.sac_membership.tour_guide") }
      expect(tour_guide).to be_nil
    end
  end

  describe "#extra_apple_fields" do
    it "includes stammsektion in secondaryFields" do
      fields = subject.extra_apple_fields
      expect(fields[:secondaryFields]).to be_present
      expect(fields[:secondaryFields].first[:value]).to eq(person.primary_group.layer_group.name)
    end

    it "includes zusatzsektionen in auxiliaryFields when present" do
      fields = subject.extra_apple_fields
      expect(fields[:auxiliaryFields]).to be_present
      expect(fields[:auxiliaryFields].first[:value]).to include("SAC Matterhorn")
    end

    it "omits auxiliaryFields when person has no additional sections" do
      person.roles.where(type: Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name).destroy_all
      fields = subject.extra_apple_fields
      expect(fields[:auxiliaryFields]).to be_nil
    end

    it "includes tour guide in backFields when person is active tour guide" do
      person.qualifications.create!(
        qualification_kind: qualification_kinds(:ski_leader),
        start_at: 1.month.ago
      )
      person.roles.create!(
        type: Group::SektionsTourenUndKurse::Tourenleiter.sti_name,
        group: groups(:matterhorn_touren_und_kurse)
      )
      fields = subject.extra_apple_fields
      expect(fields[:backFields]).to be_present
      expect(fields[:backFields].first[:value]).to eq(I18n.t("passes.sac_membership.tour_guide_active"))
    end

    it "omits backFields when person is not a tour guide" do
      fields = subject.extra_apple_fields
      expect(fields[:backFields]).to be_nil
    end
  end
end
