# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Groups::SelfRegistrationController do
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }

  def wizard_params(step: 0, **attrs)
    {
      group_id: group.id,
      step: step
    }.merge(wizards_signup_sektion_wizard: attrs)
  end

  context "with existing email" do
    let(:admin) { people(:admin) }

    it "redirects to login page" do
      post :create, params: wizard_params(main_email_field: {email: admin.email})
      expect(response).to redirect_to(new_person_session_path(person: {login_identity: admin.email}))
      expect(flash[:notice]).to eq "Es existiert bereits ein Login für diese E-Mail. Melde dich hier an."
    end
  end
end
