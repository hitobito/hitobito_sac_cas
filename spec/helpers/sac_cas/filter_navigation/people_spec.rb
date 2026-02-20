# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "FilterNavigation::People" do
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:person) { Fabricate.build(:person) }
  let(:group) {
    Fabricate.build(described_class.sti_name, id: 1, layer_group: groups(:root)).decorate
  }
  let(:params) { {group_id: group.id} }

  let(:filter_list) { Person::Filter::List.new(group, nil) }
  let(:filter) { FilterNavigation::People.new(self, group, filter_list) }

  subject(:dom) { Capybara::Node::Simple.new(filter.to_s) }

  before do
    allow(self).to receive(:can?).and_return(true)
    allow(self).to receive(:current_user).and_return(person)
  end

  shared_examples "having Tourenleiter filters" do
    let(:tourenleiter_ids) {
      SacCas::FilterNavigation::People::TOURENLEITER_ROLES.map(&:type_id).join("-")
    }
    let(:kind_ids) { QualificationKind.pluck(:id).map(&:to_s) }

    def parse_link_query(link)
      link = dom.find_link(link)
      Rack::Utils.parse_query(URI.parse(link[:href]).query)
    end

    it "has common shared filter attributes" do
      ["Aktive Tourenleiter",
        "Sistierte Tourenleiter",
        "Inaktive Tourenleiter",
        "Keine Tourenleiter",
        "Abgelaufene Tourenleiter"].each do |label|
        query = parse_link_query(label)
        expect(query["name"]).to eq label
        expect(query["range"]).to eq "deep"
      end
    end

    it "Aktive Tourenleiter filters for role only" do
      query = parse_link_query("Aktive Tourenleiter")
      expect(query["filters[role][role_type_ids]"]).to eq tourenleiter_ids
      expect(query["filters[role][kind]"]).to eq "active_today"
    end

    it "Sistierte Tourenleiter filters for not_active_but_reactivateable qualifications only" do
      query = parse_link_query("Sistierte Tourenleiter")
      expect(query["filters[role][role_type_ids]"]).to eq tourenleiter_ids
      expect(query["filters[role][kind]"]).to eq "active"
      expect(query["filters[qualification][validity]"]).to eq "not_active_but_reactivateable"
      # rubocop:todo Layout/LineLength
      expect(query["filters[qualification][qualification_kind_ids]"].split("-")).to match_array(kind_ids)
      # rubocop:enable Layout/LineLength
    end

    it "Inaktive Tourenleiter filters for role and active qualifications" do
      query = parse_link_query("Inaktive Tourenleiter")
      expect(query["filters[role][role_type_ids]"]).to eq tourenleiter_ids
      expect(query["filters[role][kind]"]).to eq "inactive_but_existing"
      expect(query["filters[qualification][validity]"]).to eq "active"
      # rubocop:todo Layout/LineLength
      expect(query["filters[qualification][qualification_kind_ids]"].split("-")).to match_array(kind_ids)
      # rubocop:enable Layout/LineLength
    end

    it "Keine Tourenleiter filters for none qualifications only" do
      query = parse_link_query("Keine Tourenleiter")
      expect(query["filters[role][role_type_ids]"]).to eq tourenleiter_ids
      expect(query["filters[role][kind]"]).to eq "inactive"
      expect(query["filters[qualification][validity]"]).to eq "none"
      # rubocop:todo Layout/LineLength
      expect(query["filters[qualification][qualification_kind_ids]"].split("-")).to match_array(kind_ids)
      # rubocop:enable Layout/LineLength
    end

    it "Abgelaufene Tourenleiter filters for only_expired qualifications only" do
      query = parse_link_query("Abgelaufene Tourenleiter")
      expect(query["filters[role][role_type_ids]"]).to eq tourenleiter_ids
      expect(query["filters[role][kind]"]).to eq "active"
      expect(query["filters[qualification][validity]"]).to eq "only_expired"
      # rubocop:todo Layout/LineLength
      expect(query["filters[qualification][qualification_kind_ids]"].split("-")).to match_array(kind_ids)
      # rubocop:enable Layout/LineLength
    end
  end

  describe Group::SacCas do
    it "has Neuanmeldungen filter" do
      expect(dom).to have_link "Neuanmeldungen"
    end

    it_behaves_like "having Tourenleiter filters"
  end

  describe Group::Sektion do
    it_behaves_like "having Tourenleiter filters"
  end

  describe Group::Ortsgruppe do
    it_behaves_like "having Tourenleiter filters"
  end

  describe "full cycle" do
    let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg).decorate }
    let(:user) { people(:tourenchef) }
    let(:touren_group) { groups(:bluemlisalp_ortsgruppe_ausserberg_touren_und_kurse) }
    let(:mitglieder) { groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder) }
    let(:quali_kind) { qualification_kinds(:ski_leader) }
    let(:today) { Time.zone.today }

    def entries(label)
      link = dom.find_link(label)
      params = Rack::Utils.parse_nested_query(URI.parse(link[:href]).query).with_indifferent_access
      Person::Filter::List.new(group, user, params).entries
    end

    def create_person(name, tl_start: nil, tl_end: nil, quali_start: tl_start,
      member_start: tl_start, member_end: nil)
      person = Fabricate(:person, last_name: name)
      if quali_start
        person.qualifications.create!(qualification_kind: quali_kind,
          start_at: quali_start)
      end
      if tl_start
        # rubocop:todo Layout/LineLength
        role = quali_start ? Group::SektionsTourenUndKurse::Tourenleiter : Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation
        # rubocop:enable Layout/LineLength
        Fabricate(role.name.to_sym, person: person, group: touren_group, start_on: tl_start,
          end_on: tl_end)
      end
      Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym, person: person, group: mitglieder,
        start_on: member_start, end_on: member_end || today.end_of_year)
      person
    end

    before do
      quali_kind.update!(validity: 6, reactivateable: 4)

      @tl_with_quali = create_person("tl with quali", tl_start: 1.year.ago)
      @tl_without_quali = create_person("tl without quali", tl_start: 1.year.ago, quali_start: nil)
      @old_tl_without_quali = create_person("old tl without quali", tl_start: 5.years.ago,
        tl_end: 1.year.ago, quali_start: nil)
      @old_tl_without_quali_without_membership = create_person(
        # rubocop:todo Layout/LineLength
        "old tl without quali without membership", tl_start: 5.years.ago, tl_end: 2.year.ago, quali_start: nil, member_end: 2.years.ago
      )
      # rubocop:enable Layout/LineLength
      @old_tl_without_quali_with_recently_ended_membership = create_person(
        # rubocop:todo Layout/LineLength
        "old tl without quali with recently ended membership", tl_start: 5.years.ago, tl_end: 1.year.ago, quali_start: nil, member_end: 1.month.ago
      )
      # rubocop:enable Layout/LineLength
      @old_tl_with_quali = create_person("old tl with quali", tl_start: 3.years.ago,
        tl_end: 1.year.ago)
      @old_tl_with_quali_without_membership = create_person("old tl with quali without membership",
        tl_start: 3.years.ago, tl_end: 2.year.ago, member_end: 2.years.ago)
      @tl_with_stalled_quali = create_person("tl with stalled quali", tl_start: 8.years.ago)
      @old_tl_with_stalled_quali = create_person("old tl with stalled quali",
        tl_start: 8.years.ago, tl_end: 1.year.ago)
      @old_tl_with_stalled_quali_without_membership = create_person(
        # rubocop:todo Layout/LineLength
        "old tl with stalled quali without membership", tl_start: 8.years.ago, tl_end: 2.year.ago, member_end: 2.years.ago
      )
      # rubocop:enable Layout/LineLength
      @tl_with_expired_quali = create_person("tl with expired quali", tl_start: 20.years.ago)
      @old_tl_with_expired_quali = create_person("old tl with expired quali",
        tl_start: 20.years.ago, tl_end: 1.year.ago)
      @old_tl_with_expired_quali_without_membership = create_person(
        # rubocop:todo Layout/LineLength
        "old tl with expired quali without membership", tl_start: 20.years.ago, tl_end: 2.year.ago, member_end: 2.years.ago
      )
      # rubocop:enable Layout/LineLength
      @no_tl_with_quali = create_person("no tl with quali", tl_start: nil, quali_start: 1.year.ago,
        member_start: 1.year.ago)
      @no_tl_without_quali = create_person("no tl without quali", tl_start: nil,
        member_start: 1.year.ago)
      @no_tl_with_stalled_quali = create_person("no tl with stalled quali", tl_start: nil,
        quali_start: 8.years.ago, member_start: 8.years.ago)
      @no_tl_with_expired_quali = create_person("no tl with expired quali", tl_start: nil,
        quali_start: 20.years.ago, member_start: 20.years.ago)
      @no_tl_with_quali_without_membership = create_person("no tl with quali without membership",
        tl_start: nil, quali_start: 1.year.ago, member_start: 8.years.ago, member_end: 2.years.ago)
      @no_tl_without_quali_without_membership = create_person(
        # rubocop:todo Layout/LineLength
        "no tl without quali without membership", tl_start: nil, member_start: 8.years.ago, member_end: 2.years.ago
      )
      # rubocop:enable Layout/LineLength
    end

    it "filters Aktive Tourenleiter" do
      list = entries("Aktive Tourenleiter")
      expect(list.map(&:last_name)).to match_array([@tl_with_quali, @tl_without_quali,
        @tl_with_stalled_quali, @tl_with_expired_quali].map(&:last_name))
    end

    it "filters Sistierte Tourenleiter" do
      list = entries("Sistierte Tourenleiter")
      expect(list.map(&:last_name)).to match_array([@tl_with_stalled_quali,
        @old_tl_with_stalled_quali].map(&:last_name))
    end

    it "filters Inaktive Tourenleiter" do
      list = entries("Inaktive Tourenleiter")
      expect(list.map(&:last_name)).to match_array([@old_tl_with_quali].map(&:last_name))
    end

    it "filters Abgelaufene Tourenleiter" do
      list = entries("Abgelaufene Tourenleiter")
      expect(list.map(&:last_name)).to match_array([@tl_with_expired_quali,
        @old_tl_with_expired_quali].map(&:last_name))
    end

    it "filters Keine Tourenleiter" do
      list = entries("Keine Tourenleiter")
      # rubocop:todo Layout/LineLength
      # @old_tl_without_quali_with_recently_ended_membership is included because of Settings.person.ended_roles_readable_for = 1.year
      # rubocop:enable Layout/LineLength
      expect(list.map(&:last_name)).to match_array([@no_tl_without_quali, @old_tl_without_quali,
        @old_tl_without_quali_with_recently_ended_membership, people(:tourenchef)].map(&:last_name))
    end
  end
end
