# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::JoinZusatzsektionsController do
  before { sign_in(operator) }

  let(:operator) { person }
  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:matterhorn) { groups(:matterhorn) }

  def build_params(step:, **attrs)
    {step:, wizards_memberships_join_zusatzsektion: attrs}
  end

  describe "#GET" do
    let(:request) do
      get group_person_join_zusatzsektion_path(group_id: bluemlisalp.id, person_id: person.id)
    end
    let(:person) { people(:mitglied) }

    def expect_wizard_form
      expect(response).to be_successful
      expect(response.body).to include "Zusatzsektion beitreten"
      expect(response.body).to include "Sektion wählen"
      expect(response.body).to include "Weiter"
    end

    context "as normal user" do
      it "renders the form" do
        request
        expect_wizard_form
      end
    end

    context "with a terminated membership" do
      before do
        membership_role = person.roles.first
        membership_role.write_attribute(:terminated, true)
        membership_role.save!
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

    context "with a family user" do
      let(:person) { people(:familienmitglied) }

      it "starts with the family step" do
        request
        expect_wizard_form
        expect(response.body).to include "Familienmitgliedschaft"
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

      it "renders the form" do
        request
        expect_wizard_form
      end
    end
  end

  describe "#POST" do
    let(:request) do
      post group_person_join_zusatzsektion_path(group_id: bluemlisalp.id, person_id: person.id),
        params:
    end
    let(:person) { people(:mitglied) }
    let(:params) { build_params(step: 1, choose_sektion: {group_id: matterhorn.id}) }

    before do
      Group::SektionsNeuanmeldungenSektion.delete_all
      ids = %w[mitglied_zweitsektion familienmitglied_zweitsektion].map do |key|
        ActiveRecord::FixtureSet.identify(key)
      end
      Role.where(id: ids).delete_all
    end

    context "as normal user" do
      it "POST#create creates single role and redirects" do
        expect { request }.to change(Role, :count).by(1)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Deine Zusatzmitgliedschaft in <i>SAC " \
                                     "Matterhorn</i> wurde erstellt."
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

      it "POST#create creates single role and redirects" do
        expect { request }.to change(Role, :count).by(1)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Deine Zusatzmitgliedschaft in <i>SAC " \
                                     "Matterhorn</i> wurde erstellt."
      end
    end

    context "as family" do
      let(:person) { people(:familienmitglied) }
      let(:params) do
        build_params(step: 2, choose_sektion: {group_id: matterhorn.id},
          choose_membership: {register_as: :family})
      end

      it "POST#create creates multiple roles and redirects" do
        expect { request }.to change(Role, :count).by(3)
        expect(response).to redirect_to person_path(person, format: :html)
        expect(flash[:notice]).to eq "Eure 3 Zusatzmitgliedschaften in <i>SAC " \
                                     "Matterhorn</i> wurden erstellt."
      end
    end
  end
end
