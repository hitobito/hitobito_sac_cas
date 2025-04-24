# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Person::SecurityToolsController do
  let(:admin) { people(:admin) }
  let(:person) { people(:mitglied) }

  before { sign_in(admin) }

  describe "POST#password_override" do
    it "creates papertrail version of expected event", versioning: true do
      expect do
        post :password_override, params: {group_id: person.primary_group_id, id: person.id}
      end.to change { PaperTrail::Version.count }.by(1)
        .and change { person.reload.versions.count }.by(1)

      expect(person.versions.last.event).to eq Person::PAPER_TRAIL_PASSWORD_OVERRIDE_EVENT.to_s
    end
  end
end
