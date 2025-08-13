# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe People::AccountCompletionsController do
  let(:person) { Fabricate(:person, email: nil) }
  let(:account_completion) { AccountCompletion.create!(person:) }

  it "raises 404 if token does not exist" do
    expect do
      get :show, params: {token: "asdf"}
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "raises 404 if email for that token has been confirmed" do
    person.update(email: "test@example.com")
    expect do
      get :show, params: {token: account_completion.token}
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe "GET#show" do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    it "renders form with token as hidden field" do
      get :show, params: {token: account_completion.token}
      expect(dom).to have_css("form")
      hidden_token_field = dom.find("input[name=token]", visible: false)
      expect(hidden_token_field["value"]).to eq account_completion.token
    end

    it "shows flash instead of form if token expired" do
      account_completion.update_columns(created_at: 4.months.ago)
      get :show, params: {token: account_completion.token}
      expect(dom).not_to have_css("form")
      expect(dom).to have_css(".alert-danger", text: "Das verwendete Token ist nicht mehr gültig.")
      expect(flash.now[:alert]).to eq "Das verwendete Token ist nicht mehr gültig."
    end
  end

  describe "PUT#update" do
    it "validates model" do
      patch :update, params: {token: account_completion.token, account_completion: {
        email: "test@example.com",
        email_confirmation: "test1@example.com",
        password: "testtesttest",
        password_confirmation: "testtesttest1"
      }}
      expect(response.status).to eq 422
    end

    it "updates person sends email and redirects on success" do
      expect do
        patch :update, params: {token: account_completion.token, account_completion: {
          email: "test@example.com",
          email_confirmation: "test@example.com",
          password: "testtesttest",
          password_confirmation: "testtesttest"
        }}
        expect(response).to redirect_to(person_path(person))
        expect(flash[:notice]).to eq "Du erhältst in wenigen Minuten eine E-Mail, mit der Du " \
          "Deine E-Mail-Adresse bestätigen kannst."
      end.to change(ActionMailer::Base.deliveries, :count).by(1)
        .and change { person.reload.unconfirmed_email }.from(nil).to("test@example.com")
    end
  end
end
