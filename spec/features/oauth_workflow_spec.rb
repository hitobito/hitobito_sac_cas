# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe "OauthWorkflow" do
  let(:redirect_uri) { "urn:ietf:wg:oauth:2.0:oob" }
  let(:app) { Oauth::Application.create!(name: "MyApp", redirect_uri: redirect_uri) }
  let(:authorize_path) do
    oauth_authorization_path(
      client_id: app.uid,
      redirect_uri: redirect_uri,
      response_type: "code",
      scope: "name email"
    )
  end

  def fill_in_basic_login_wizard
    fill_in "Geburtsdatum", with: "01.01.1980"
    fill_in "Adresse", with: "Musterplatz"
    fill_in "wizards_signup_abo_basic_login_wizard_person_fields_housenumber", with: "42"
    fill_in "PLZ/Ort", with: "40202"
    fill_in "wizards_signup_abo_basic_login_wizard_person_fields_town", with: "Zürich"
    find(:label, "Land").click
    find(:option, text: "Vereinigte Staaten").click
    check "Ich habe die Datenschutzerklärung gelesen und stimme dieser zu"
  end

  it "for user without active role redirects to self-registration with completion_redirect_path" do
    sign_in(people(:roleless))

    visit authorize_path

    expect(page).to have_current_path(
      group_self_registration_path(group_id: Group::AboBasicLogin.first!, locale: I18n.locale),
      ignore_query: true
    )

    redirect_field_id = "completion_redirect_path"
    expect(page).to have_field redirect_field_id, type: :hidden

    redirect_path = find("##{redirect_field_id}", visible: false).value
    expect(redirect_path).to eq authorize_path

    form = page.find("form#new_wizards_signup_abo_basic_login_wizard")
    expect(form.native["data-turbo"]).to eq "false"
  end

  it "for user without active role redirects back to authorize after completing self-reg" do
    sign_in(people(:roleless))
    visit authorize_path

    fill_in_basic_login_wizard
    click_button "SAC-KONTO ERSTELLEN"

    expect(page).to have_content "Autorisierung erforderlich"
    expect(page).to have_current_path(authorize_path)
  end

  it "for user with active role shows the authorization page" do
    sign_in(people(:abonnent))

    visit authorize_path

    expect(page).to have_content "Autorisierung erforderlich"
    expect(page).to have_current_path(authorize_path)
  end
end
