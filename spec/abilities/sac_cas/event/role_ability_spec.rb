# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::RoleAbility do
  subject(:ability) { Ability.new(role.person.reload) }

  context "any" do
    let(:person) { people(:tourenchef) }

    context "on course" do
      let(:top_course) { events(:top_course) }
      let(:participation) { Event::Participation.create!(event: top_course, person: person, application_id: -1) }

      context "as leader" do
        let(:role) { Fabricate("Event::Course::Role::Leader", participation: participation) }

        [:show, :create, :update, :destroy].each do |action|
          it "may not #{action}" do
            expect(subject).not_to be_able_to(action, role)
          end
        end
      end

      context "as assistant leader" do
        let(:role) { Fabricate("Event::Course::Role::AssistantLeader", participation: participation) }

        [:show, :create, :update, :destroy].each do |action|
          it "may not #{action}" do
            expect(subject).not_to be_able_to(action, role)
          end
        end
      end
    end
  end
end
