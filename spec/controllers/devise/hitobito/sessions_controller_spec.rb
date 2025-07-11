# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Devise::Hitobito::SessionsController do
  before do
    request.env["devise.mapping"] = Devise.mappings[:person]
  end

  let(:person) { people(:mitglied) }

  describe "#create with unconfirmed email" do
    let(:password) { "a" * 12 }

    before { person.update!(confirmed_at: nil, password:, password_confirmation: password) }

    it "responds with standard message if password does not match" do
      post :create, params: {person: {login_identity: person.email, password: "test"}}
      expect(flash.alert.strip).to eq "Ungültige Anmeldedaten."
    end

    it "informs and sends confirmation email" do
      expect do
        post :create, params: {person: {login_identity: person.email, password:}}
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(response).to redirect_to new_person_session_path
      expect(ActionMailer::Base.deliveries.last.subject).to eq "Anleitung zur Bestätigung Deiner E-Mail-Adresse"
      expect(flash.alert.strip).to eq <<~TEXT.tr("\n", " ").strip
        Bitte bestätige Deine E-Mail-Adresse, bevor Du fortfahren kannst. Wir haben Dir soeben eine Bestätigungs-E-Mail geschickt.
        Falls deine E-Mail-Adresse nicht mehr gültig ist oder du (auch im SPAM-Ordner) keine E-Mail erhalten hast:
        Wende dich bitte mit Angabe deiner E-Mail an <a href="mail_to:mv@sac-cas.ch">mv@sac-cas.ch</a>.
      TEXT
    end
  end
end
