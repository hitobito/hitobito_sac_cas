# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe People::AccountCompletionsController do
  let!(:person) { Fabricate(:person, email: nil) }
  let!(:token) { person.generate_token_for(:account_completion) }

  describe "GET#show" do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    it "redirects if token does not exist" do
      get :show, params: {token: "asdf"}
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq "Das verwendete Token ist nicht gültig."
    end

    it "redirects if token is expired" do
      travel_to(4.months.from_now) do
        get :show, params: {token:}
      end
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq "Das verwendete Token ist nicht gültig."
    end

    it "renders form with token as hidden field" do
      get :show, params: {token:}
      expect(dom).to have_css("form")
      hidden_token_field = dom.find("input[name=token]", visible: false)
      expect(hidden_token_field["value"]).to eq token
    end
  end

  describe "PUT#update" do
    it "redirects if trying to update with invalid token" do
      patch :update, params: {token: "asdf"}
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq "Das verwendete Token ist nicht gültig."
    end

    it "validates email and password" do
      patch :update, params: {token:, person: {
        unconfirmed_email: "",
        password: "testtest",
        password_confirmation: "testtesttest1"
      }}
      expect(response.status).to eq 422
      expect(assigns(:person).errors.to_a).to eq [
        "Passwort Bestätigung stimmt nicht mit Passwort überein",
        "Passwort ist zu kurz (weniger als 12 Zeichen)"
      ]
    end

    it "updates person sends email and redirects on success" do
      expect do
        patch :update, params: {token:, person: {
          unconfirmed_email: "test@example.com",
          password: "testtesttest",
          password_confirmation: "testtesttest"
        }}
        expect(response).to redirect_to(new_person_session_path)
        expect(flash[:notice]).to eq [
          "Du erhältst in wenigen Minuten eine E-Mail, mit der Du Deine E-Mail-Adresse bestätigen kannst.",
          "Sobald du deine E-Mail Adresse bestätigt hast, kannst du dich hier anmelden."
        ]
      end.to change(ActionMailer::Base.deliveries, :count).by(1)
        .and change { person.reload.unconfirmed_email }.from(nil).to("test@example.com")
    end
  end
end
