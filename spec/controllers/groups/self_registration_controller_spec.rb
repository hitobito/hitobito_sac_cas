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

  describe "completing wizard" do
    let(:required_params) {
      wizard_params(
        main_email_field: {
          email: "max.muster@example.com"
        },
        person_fields: {
          gender: "_nil",
          first_name: "Max",
          last_name: "Muster",
          address_care_of: "c/o Musterleute",
          street: "Musterplatz",
          housenumber: "42",
          postbox: "Postfach 23",
          town: "Zurich",
          zip_code: "8000",
          birthday: "1.1.2000",
          country: "CH",
          phone_number: "+41 79 123 45 67"
        },
        various_fields: {},
        summary_fields: {
          statutes: true,
          contribution_regulations: true,
          data_protection: true
        }
      )
    }

    context "anonymous" do
      it "redirects to login" do
        post :create, params: required_params.merge(step: 4)
        expect(response).to redirect_to new_person_session_path
        expect(flash[:notice]).to eq "Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst."
      end
    end

    context "when logged in" do
      let(:abonnent) { people(:abonnent) }

      before { sign_in(abonnent) }

      it "redirects to history_group_person_path" do
        post :create, params: required_params.merge(step: 3)
        expect(response).to redirect_to history_group_person_path(group, abonnent)
        expect(flash[:notice]).to eq "Deine Anmeldung wurde erfolgreich gespeichert."
      end

      context "without active role" do
        it "redirects to history_group_person_path" do
          abonnent.roles.update_all(end_on: 1.week.ago)
          post :create, params: required_params.merge(step: 3)
          expect(response).to redirect_to history_group_person_path(group, abonnent)
          expect(flash[:notice]).to eq "Deine Anmeldung wurde erfolgreich gespeichert."
        end
      end
    end
  end

  context "without email" do
    it "redirects to login page" do
      Person.create!(first_name: "noemail")
      post :create, params: wizard_params
      expect(response).to render_template(:show)
    end
  end

  context "with existing email" do
    let(:admin) { people(:admin) }

    it "redirects to login page" do
      post :create, params: wizard_params(main_email_field: {email: admin.email})
      expect(response).to redirect_to(new_person_session_path(person: {login_identity: admin.email}))
      expect(flash[:notice]).to eq "Es existiert bereits ein Login für diese E-Mail. Melde dich hier an."
    end
  end

  context "when signed in" do
    before { sign_in(person) }

    context "with existing membership" do
      let(:person) { people(:mitglied) }

      it "redirects to memberships tab with a flash message" do
        get :show, params: wizard_params

        expect(response).to redirect_to(history_group_person_path(group_id: person.primary_group_id, id: person.id))
        expect(flash[:notice]).to eq "Du besitzt bereits eine SAC-Mitgliedschaft. Wenn du diese anpassen möchtest, kontaktiere bitte die SAC-Geschäftsstelle."
      end
    end

    context "with existing family" do
      let(:person) { people(:familienmitglied) }

      before { Role.where(id: roles(:familienmitglied).id).delete_all }

      it "redirects to memberships tab with a flash message" do
        get :show, params: wizard_params

        expect(response).to redirect_to(history_group_person_path(group_id: person.primary_group_id, id: person.id))
        expect(flash[:notice]).to eq "Du ist einer Familie zugeordnet. Kontaktiere bitte die SAC-Geschäftsstelle."
      end
    end

    context "without primary group id" do
      let(:person) { Fabricate(:person) }

      it "redirects to memberships tab layered under root group with a flash message" do
        allow_any_instance_of(Wizards::Signup::SektionWizard).to receive(:member_or_applied?).and_return(true)
        get :show, params: wizard_params

        expect(response).to redirect_to(history_group_person_path(group_id: Group.root.id, id: person.id))
        expect(flash[:notice]).to eq "Du besitzt bereits eine SAC-Mitgliedschaft. Wenn du diese anpassen möchtest, kontaktiere bitte die SAC-Geschäftsstelle."
      end
    end
  end
end
