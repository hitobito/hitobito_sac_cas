# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Groups::SelfInscriptionController do
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }

  it "redirects to login" do
    sign_in(people(:mitglied))
    get :show, params: { group_id: group.id }
    expect(response).to redirect_to group_self_registration_path
  end
end
