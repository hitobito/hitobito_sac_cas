# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::TerminateSacMembershipsController do
  before { sign_in(operator) }

  let(:operator) { person }
  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:matterhorn) { groups(:matterhorn) }
  let(:role) { person.roles.find_by!(type: "Group::SektionsMitglieder::Mitglied") }

  def build_params(step:, **attrs)
    {step:, wizards_memberships_terminate_sac_membership_wizard: attrs}
  end

  describe "#GET" do
    let(:request) do
      get group_person_terminate_sac_membership_path(group_id: bluemlisalp.id, person_id: person.id)
    end
    let(:person) { people(:mitglied) }

    def expect_summary_step
      expect(response).to be_successful
      expect(response.body).to include "SAC-Mitgliedschaft beenden"
      expect(response.body).to include "Austritt beantragen"
    end

    def expect_date_select_step
      expect(response).to be_successful
      expect(response.body).to include "SAC-Mitgliedschaft beenden"
      expect(response.body).to include "Austrittsdatum"
    end

    context "as normal user" do
      it "renders the form" do
        request
        expect_summary_step
      end
    end

    context "with a terminated membership" do
      before do
        role.write_attribute(:terminated, true)
        role.save!
      end

      def expect_terminated_page
        expect(response).to be_successful
        expect(response.body).to include "Deine Mitgliedschaft ist gekündigt per"
        expect(response.body).not_to include "Weiter"
      end

      it "renders a notice" do
        request
        expect_terminated_page
      end

      context "as an admin" do
        let(:operator) { people(:admin) }

        it "renders a notice" do
          request
          expect_terminated_page
        end
      end
    end

    context "when sektion has mitglied_termination_by_section_only=true" do
      before do
        role.layer_group.update!(mitglied_termination_by_section_only: true)
      end

      it "shows an info text" do
        request
        expect(response).to be_successful
        expect(response.body).to include("Wir bitten dich den Austritt telefonisch oder per E-Mail zu beantragen.")
      end

      context "as and admin" do
        let(:operator) { people(:admin) }

        it "shows the date select step with a warning" do
          request
          expect_date_select_step
          expect(response.body).to include("Achtung: der Austritt findet bei einer Sektion statt, bei der die Austrittsfunktion für das Mitglied deaktiviert ist.")
        end
      end
    end

    context "with a family main person" do
      let(:person) { people(:familienmitglied) }

      it "shows info about affecting the whole family" do
        request
        expect_summary_step
        expect(response.body).to include "Achtung: der Austritt wird für die gesamte Familienmitgliedschaft beantragt."
      end
    end

    context "with a family regular person" do
      let(:person) { people(:familienmitglied2) }

      it "shows info about the main family person" do
        request
        expect(response.body).to include "Bitte wende dich an #{people(:familienmitglied)}"
      end
    end

    context "as a different user" do
      let(:operator) { people(:familienmitglied) }

      it "returns not authorized" do
        expect { request }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as an admin" do
      let(:operator) { people(:admin) }

      it "shows me the select date step" do
        request
        expect_date_select_step
      end
    end
  end

  describe "#POST" do
    let(:termination_reason_id) { termination_reasons(:deceased).id }
    let(:request) do
      post group_person_terminate_sac_membership_path(group_id: bluemlisalp.id, person_id: person.id),
        params:
    end
    let(:person) { people(:mitglied) }
    let(:params) { build_params(step: 0, summary: {termination_reason_id:}) }

    context "as normal user" do
      it "marks single role as destroyed and redirects" do
        expect do
          request
          role.reload
        end
          .to not_change(Role, :count)
          .and change { role.terminated }.to(true)
          .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Deine SAC-Mitgliedschaft wurde gekündet."
      end
    end

    context "as a different user" do
      let(:operator) { people(:familienmitglied) }

      it "returns not authorized" do
        expect { request }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as an admin" do
      let(:operator) { people(:admin) }
      let(:params) { build_params(step: 1, termination_choose_date: {terminate_on: "now"}, summary: {termination_reason_id:}) }

      it "can choose immediate termination, destroy single role and redirects" do
        expect do
          request
          role.reload
        end
          .to change(Role, :count).by(-2)
          .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Deine SAC-Mitgliedschaft wurde gekündet."
      end
    end

    context "as family" do
      let(:person) { people(:familienmitglied) }

      it "creates multiple roles and redirects" do
        expect do
          request
          role.reload
        end
          .to not_change(Role, :count)
          .and change { role.terminated }.to(true)
          .and change { role.termination_reason_id }.from(nil).to(termination_reason_id)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Eure 3 SAC-Mitgliedschaften wurden gekündet."
      end
    end
  end
end
