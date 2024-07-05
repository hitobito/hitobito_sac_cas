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
  let(:group) { Fabricate.build(described_class.sti_name, id: 1).decorate }
  let(:params) { {group_id: group.id} }

  let(:filter_list) { Person::Filter::List.new(group, nil) }
  let(:filter) { FilterNavigation::People.new(self, group, filter_list) }

  subject(:dom) { Capybara::Node::Simple.new(filter.to_s) }

  before do
    allow(self).to receive(:can?).and_return(true)
    allow(self).to receive(:current_user).and_return(person)
  end

  shared_examples "having Tourenleiter filters" do
    let(:tourenleiter_id) { Group::SektionsTourenkommission::Tourenleiter.id.to_s }
    let(:kind_ids) { QualificationKind.pluck(:id).map(&:to_s) }

    def parse_link_query(link)
      link = dom.find_link(link)
      CGI.parse(URI.parse(link[:href]).query)
        .transform_values { |v| v.one? ? v.first : v }
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
      expect(query["filters[role][role_type_ids]"]).to eq tourenleiter_id
      expect(query["filters[role][kind]"]).to eq "active"
    end

    it "Sistierte Tourenleiter filters for not_active_but_reactivateable qualifications only" do
      query = parse_link_query("Sistierte Tourenleiter")
      expect(query["filters[role]"]).to be_nil
      expect(query["filters[qualification][validity]"]).to eq "not_active_but_reactivateable"
      expect(query["filters[qualification][qualification_kind_ids]"].split("-")).to match_array(kind_ids)
    end

    it "Inaktive Tourenleiter filters for role and active qualifications" do
      query = parse_link_query("Inaktive Tourenleiter")
      expect(query["filters[role][role_type_ids]"]).to eq tourenleiter_id
      expect(query["filters[role][kind]"]).to eq "inactive"
      expect(query["filters[qualification][validity]"]).to eq "active"
      expect(query["filters[qualification][qualification_kind_ids]"].split("-")).to match_array(kind_ids)
    end

    it "Keine Tourenleiter filters for none qualifications only" do
      query = parse_link_query("Keine Tourenleiter")
      expect(query["filters[role]"]).to be_nil
      expect(query["filters[qualification][validity]"]).to eq "none"
      expect(query["filters[qualification][qualification_kind_ids]"].split("-")).to match_array(kind_ids)
    end

    it "Abgelaufene Tourenleiter filters for only_expired qualifications only" do
      query = parse_link_query("Abgelaufene Tourenleiter")
      expect(query["filters[role]"]).to be_nil
      expect(query["filters[qualification][validity]"]).to eq "only_expired"
      expect(query["filters[qualification][qualification_kind_ids]"].split("-")).to match_array(kind_ids)
    end
  end

  describe Group::SacCas do
    it "has Neuanmeldunge filter" do
      expect(dom).to have_link "Neuanmeldungen"
    end

    it_behaves_like "having Tourenleiter filters"
  end

  describe Group::Sektion do
    it_behaves_like "having Tourenleiter filters"
  end
end
