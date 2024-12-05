# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe People::Neuanmeldungen::ApprovesController do
  include Households::SpecHelper
  before { sign_in(people(:admin)) }

  context "POST create" do
    let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
    let(:people_ids) { %i[abonnent mitglied tourenchef].map { |p| people(p).id } }

    subject(:send_request) do
      post :create, params: {group_id: group.id, ids: people_ids.join(",")}
    end

    it "calls People::Neuanmeldungen::Approve::call" do
      approver = People::Neuanmeldungen::Approve.new
      expect(People::Neuanmeldungen::Approve).to receive(:new).and_return(approver)
      expect(approver).to receive(:attributes=).with({group: group, people_ids: people_ids})
      expect(approver).to receive(:call)

      send_request
    end

    it "sets the flash message" do
      send_request

      expect(flash[:notice]).to eq("3 Anmeldungen wurden übernommen")
    end

    context "with family members" do
      let(:people_ids) do
        family_person = Fabricate(:person, sac_family_main_person: true)
        Fabricate(
          Group::SektionsMitglieder::Mitglied.sti_name,
          group: groups(:matterhorn_mitglieder),
          person: family_person,
          start_on: 2.years.ago.beginning_of_year
        )
        create_household(family_person, Fabricate(:person), Fabricate(:person, birthday: 15.years.ago))
        Fabricate(
          Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion.sti_name.to_sym,
          group: group,
          beitragskategorie: :family,
          created_at: Time.zone.now.beginning_of_year,
          person: family_person
        ).tap { |r| r.update_columns(start_on: 1.day.ago) }

        family_person.household.people.map(&:id) + [people(:abonnent).id]
      end

      it "approves all 3 family members and sets the flash message" do
        send_request

        expect(flash[:notice]).to eq("4 Anmeldungen wurden übernommen")
      end
    end

    it "redirects to the group people list" do
      send_request

      expect(response).to redirect_to(group_people_path(group_id: group.id))
    end
  end
end
