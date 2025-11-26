# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Groups::SelfRegistrationController, type: :controller do
  render_views

  let(:role_type) { Group::AboMagazin::Abonnent }
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:person) { people(:abonnent) }

  context "with feature enabled" do
    context "GET#show" do
      context "when registration active" do
        before do
          # rubocop:todo Layout/LineLength
          group.update(self_registration_role_type: Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name)
          # rubocop:enable Layout/LineLength
          person.update(country: "CH")
          person.phone_numbers.create(label: "Mobil", number: "0791234567")
        end

        context "when authorized" do
          it "does not redirect to self_inscription_path" do
            sign_in(person)

            get :show, params: {group_id: group.id}

            expect(response).not_to redirect_to(group_self_inscription_path(group.id))
          end

          it "contains the users data pre-filled" do
            sign_in(person)

            get :show, params: {group_id: group.id}
            expect(response.body).to have_field("Vorname")
            expect(response.body).to have_field("Vorname", with: person.first_name)
            expect(response.body).to have_field("Nachname", with: person.last_name)
          end
        end

        context "when not signed in" do
          it "renders self registration" do
            get :show, params: {group_id: group.id}

            expect(response).to render_template("self_registration/show")
          end

          context "for neuanmeldungen nv" do
            let(:neuanmeldung_nv_group) { groups(:bluemlisalp_neuanmeldungen_nv) }

            it "renders self registration with deleted neuanmeldungen group" do
              group.destroy!

              get :show, params: {group_id: neuanmeldung_nv_group.id}

              expect(response).to render_template("self_registration/show")
            end
          end
        end
      end
    end
  end
end
