# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::Role do
  context "paper trails", versioning: true do
    let(:event) { events(:top_course) }
    let(:participation) { Fabricate.build(:event_participation, event:) }
    let(:role) { Fabricate.build(Event::Role::Leader.sti_name, participation:) }

    before do
      role.save!
      PaperTrail::Version.destroy_all # make sure to start from a clean state
    end

    it "creates paper trail version on event on state change" do
      expect do
        role.update!(type: Event::Role::Cook.sti_name)
      end.to change { PaperTrail::Version.where(main: participation.event).count }.by(1)
    end

    it "does not create paper trails version on event when state did not change" do
      expect do
        role.update!(label: "something")
      end.not_to change { PaperTrail::Version.where(main: participation.event).count }
    end
  end
end
