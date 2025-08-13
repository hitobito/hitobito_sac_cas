# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Devise::ConfirmationsController do
  let(:person) { Fabricate(:person, email: nil) }
  let!(:account_completion) { AccountCompletion.create!(person:) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:person]
    person.update(confirmation_token: account_completion.token, unconfirmed_email: "test@example.com")
  end

  it "GET#show deletes account completion" do
    expect do
      get :show, params: {confirmation_token: account_completion.token}
    end.to change { AccountCompletion.count }.by(-1)
      .and change { person.reload.email }.to("test@example.com")
  end
end
