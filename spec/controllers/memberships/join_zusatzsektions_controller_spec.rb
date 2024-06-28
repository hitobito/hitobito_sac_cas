# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::JoinZusatzsektionsController do
  before { sign_in(person) }

  let(:current_user) { person }
  let(:bluemlisalp) { groups(:bluemlisalp) }
  let(:matterhorn) { groups(:matterhorn) }

  def build_params(step:, **attrs)
    {group_id: bluemlisalp.id, person_id: person.id, step: step,
     wizards_memberships_join_zusatzsektion: attrs}
  end

  before do
    Group::SektionsNeuanmeldungenSektion.delete_all
    ids = %w[mitglied_zweitsektion familienmitglied_zweitsektion].map do |key|
      ActiveRecord::FixtureSet.identify(key)
    end
    Role.where(id: ids).delete_all
  end

  context "as normal user" do
    let(:person) { people(:mitglied) }

    it "POST#create creates single role and redirects" do
      expect do
        post :create, params: build_params(step: 1, choose_sektion: {group_id: matterhorn.id})
        expect(response).to redirect_to person_path(person, format: :html)
      end.to change { Role.count }.by(1)
      expect(response).to redirect_to person_path(person, format: :html)
      expect(flash[:notice]).to eq "Deine Zusatzmitgliedschaft in <i>SAC " \
                                   "Matterhorn</i> wurde erstellt."
    end

    context "admin trys to join without membership" do
      let(:person) { people(:admin) }

      # TODO: raises a NoMethodError for append on errors when running from
      # controller for admin without membership role (unsure why)
      it "POST#create raises when admin without membership tries to join himself" do
        expect do
          post :create, params: build_params(step: 1, choose_sektion: {group_id: matterhorn.id})
        end.to raise_error(NoMethodError, /undefined method `append' for #<ActiveModel::Errors/)
      end
    end
  end

  context "as family" do
    let(:person) { people(:familienmitglied) }

    it "POST#create creates multiple roles and redirects" do
      expect do
        post :create, params: build_params(
          step: 2,
          choose_sektion: {group_id: matterhorn.id},
          choose_membership: {register_as: :family}
        )
      end.to change { Role.count }.by(3)
      expect(response).to redirect_to person_path(person, format: :html)
      expect(flash[:notice]).to eq "Eure 3 Zusatzmitgliedschaften in <i>SAC " \
                                   "Matterhorn</i> wurden erstellt."
    end
  end
end
