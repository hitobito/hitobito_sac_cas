# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Person::AddRequestAbility do
  let(:user) { Fabricate(:person) }

  subject(:ability) { Ability.new(user) }

  describe "layer_events_full" do
    let(:kommission_touren) { groups(:bluemlisalp_kommission_touren) }
    let(:event) { events(:section_tour) }

    before do
      Group::SektionsKommissionTouren::Mitglied.create!(group: kommission_touren,
        person: user)
    end

    it "is able to add without request from same layer" do
      expect(ability).to be_able_to(:add_without_request, request(people(:mitglied)))
    end

    it "is not able to add without request from ortsgruppe" do
      person = create_member(groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder))
      expect(ability).not_to be_able_to(:add_without_request, request(person))
    end

    it "is not able to add without request from other section" do
      person = create_member(groups(:matterhorn_mitglieder))
      expect(ability).not_to be_able_to(:add_without_request, request(person))
    end

    def request(person)
      Person::AddRequest::Event.new(body: event, requester: user, person: person)
    end

    def create_member(group)
      Group::SektionsMitglieder::Mitglied.create!(
        person: Fabricate(:person),
        group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
        start_on: 1.year.ago,
        end_on: Date.current.end_of_year
      ).person
    end
  end
end
