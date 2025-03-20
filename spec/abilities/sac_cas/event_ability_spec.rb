# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe EventAbility do
  let(:person) { Fabricate(:person) }
  let(:participation) { Event::Participation.create!(person:, event: events(:top_course)) }

  subject(:ability) { Ability.new(person.reload) }

  describe "manage_attachments" do
    [Event::Course::Role::Leader, Event::Course::Role::AssistantLeader].each do |role|
      before { Fabricate(role.sti_name, participation:) }

      it "is able to manage_attachments as #{role}" do
        expect(ability).to be_able_to(:manage_attachments, events(:top_course))
      end
    end

    it "is not able to manage_attachments without leader role" do
      participation.roles.destroy_all
      expect(ability).not_to be_able_to(:manage_attachments, events(:top_course))
    end
  end
end
