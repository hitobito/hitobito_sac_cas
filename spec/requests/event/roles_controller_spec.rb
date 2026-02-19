# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::RolesController do
  let(:group) { groups(:matterhorn) }

  let(:user) { people(:admin) }

  before { sign_in(user) }

  describe "GET new" do
    let(:request) {
      get new_group_event_role_path(group_id: group.id, event_id: event.id),
        params: {event_role: {type: event_role.sti_name}}
    }

    def expect_common_fields
      expect(response.body).to include("Person")
      expect(response.body).to include("Bezeichnung")
    end

    context "With course and leader" do
      let(:group) { groups(:root) }
      let(:event) { Fabricate(:course, groups: [group]) }
      let(:event_role) { Event::Course::Role::Leader }

      it "Shows the form with all the fields" do
        request
        expect(response).to be_successful
        expect_common_fields
        expect(response.body).to include("Allfällige Teilnehmer*Innen-Rolle entfernen")
        expect(response.body).to include("Selbständig erwerbend")
      end
    end

    context "With course and member" do
      let(:group) { groups(:root) }
      let(:event) { Fabricate(:course, groups: [group]) }
      let(:event_role) { Event::Course::Role::Participant }

      it "Shows the form without the self_employed field" do
        request
        expect(response).to be_successful
        expect_common_fields
        expect(response.body).not_to include("Allfällige Teilnehmer*Innen-Rolle entfernen")
        expect(response.body).not_to include("Selbständig erwerbend")
      end
    end

    context "With event and leader" do
      let(:event) { Fabricate(:event, groups: [group]) }
      let(:event_role) { Event::Role::Leader }

      it "Shows the form without the self_employed field" do
        request
        expect(response).to be_successful
        expect_common_fields
        expect(response.body).to include("Allfällige Teilnehmer*Innen-Rolle entfernen")
        expect(response.body).not_to include("Selbständig erwerbend")
      end
    end

    context "With event and member" do
      let(:event) { Fabricate(:event, groups: [group]) }
      let(:event_role) { Event::Role::Participant }

      it "Shows the form without the self_employed field" do
        request
        expect(response).to be_successful
        expect_common_fields
        expect(response.body).not_to include("Allfällige Teilnehmer*Innen-Rolle entfernen")
        expect(response.body).not_to include("Selbständig erwerbend")
      end
    end
  end
end
