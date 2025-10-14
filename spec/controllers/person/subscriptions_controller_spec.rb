# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Person::SubscriptionsController do
  let(:mitglied) { people(:mitglied) }

  before { sign_in(mitglied) }

  describe "subscribable_for: :nobody" do
    render_views  # trigger helper methods
    let(:list) { Fabricate(:mailing_list, group: groups(:root)) }

    it "hides list from subscribable" do
      get :index, params: {group_id: mitglied.roles.first.group_id, person_id: mitglied.id}
      expect(assigns(:subscribable)).not_to include(list)
    end

    it "lists list when subscribed" do
      mitglied.subscriptions.create!(mailing_list: list)
      get :index, params: {group_id: mitglied.roles.first.group_id, person_id: mitglied.id}
      expect(assigns(:subscribed)).not_to include(list)
    end

    describe "fundraising" do
      let(:list) {
        Fabricate(:mailing_list, group: groups(:root),
          internal_key: SacCas::MAILING_LIST_SPENDENAUFRUFE_INTERNAL_KEY)
      }

      it "hides list from subscribable" do
        get :index, params: {group_id: mitglied.roles.first.group_id, person_id: mitglied.id}
        expect(assigns(:subscribable)).not_to include(list)
      end

      it "hides list when subscribed" do
        mitglied.subscriptions.create!(mailing_list: list)
        get :index, params: {group_id: mitglied.roles.first.group_id, person_id: mitglied.id}
        expect(assigns(:subscribed)).not_to include(list)
      end
    end
  end
end
