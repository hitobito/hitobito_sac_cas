# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Devise::Hitobito::PasswordsController do
  before do
    request.env["devise.mapping"] = Devise.mappings[:person]
  end

  let(:user) { people(:mitglied) }

  describe "#update" do
    it "should remove legacy password hash and salt" do
      user.update!(wso2_legacy_password_hash: "old hash", wso2_legacy_password_salt: "old salt")
      token = user.generate_reset_password_token!
      put :update, params: {person: {reset_password_token: token, password: "new long password", password_confirmation: "new long password"}}
      user.reload
      expect(user.valid_password?("new long password")).to be_truthy
      expect(user.wso2_legacy_password_hash).to be_nil
      expect(user.wso2_legacy_password_salt).to be_nil
    end
  end
end
