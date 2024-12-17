# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe GroupsController, type: :request do
  let(:user) { people(:admin) }

  before { sign_in(user) }

  describe "GET groups/:id/edit" do
    let(:group) { groups(:bluemlisalp_mitglieder) }

    it "can render the edit form" do
      get edit_group_path(id: group.id)
      expect(response).to be_successful
    end
  end
end
