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

  let(:password) { "a" * 12 }
  let(:person) { people(:mitglied).tap { _1.update!(password:, password_confirmation: password) } }

  describe "#create with unconfirmed email" do
    before { person.update!(confirmed_at: nil) }

    it "responds with standard message if password does not match" do
      post :create, params: {person: {login_identity: person.email, password: "test"}}
      expect(flash.alert.strip).to eq "Ungültige Anmeldedaten."
    end

    shared_examples "informs and sends confirmation email" do |login_attribute|
      it "when logging in with #{login_attribute}" do
        expect do
          post :create, params: {person: {login_identity: person.email, password:}}
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(response).to redirect_to new_person_session_path
        expect(ActionMailer::Base.deliveries.last.subject).to eq "Anleitung zur Bestätigung Deiner E-Mail-Adresse"
        expect(flash.alert.strip).to eq <<~TEXT.tr("\n", " ").strip
          Bitte bestätige Deine E-Mail-Adresse, bevor Du fortfahren kannst. Wir haben Dir soeben eine Bestätigungs-E-Mail geschickt.<br/>
          Falls deine E-Mail-Adresse nicht mehr gültig ist oder du (auch im SPAM-Ordner) keine E-Mail erhalten hast:
          Wende dich bitte mit Angabe deiner E-Mail an <a href="mail_to:mv@sac-cas.ch">mv@sac-cas.ch</a>.
        TEXT
      end
    end

    Person.devise_login_id_attrs.each do |attr|
      it_behaves_like "informs and sends confirmation email", attr
    end
  end

  shared_examples "redirects to basic login onboarding" do
    it do
      post :create, params: {person: {login_identity: person.email, password:}}
      expect(response).to redirect_to(
        group_self_registration_path(group_id: Group::AboBasicLogin.first!,
          completion_redirect_path: root_path)
      )
    end
  end

  context "#create as user without roles" do
    before { Role.delete_all }

    it_behaves_like "redirects to basic login onboarding"
  end

  context "#create as user with ended roles" do
    before { person.roles.update_all(end_on: 1.day.ago) }

    it_behaves_like "redirects to basic login onboarding"
  end
end
