# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Person::SubscriptionsController do
  let(:mitglied) { people(:mitglied) }

  before { sign_in(mitglied) }

  render_views  # gives access to `assigns`

  describe "subscribable_for: :nobody" do
    let!(:list) { Fabricate(:mailing_list, group: groups(:root), subscribable_for: :nobody) }

    it "hides list from subscribable" do
      get :index, params: {group_id: mitglied.roles.first.group_id, person_id: mitglied.id}
      expect(assigns(:subscribable)).not_to include(list)
    end

    it "shows list when subscribed" do
      mitglied.subscriptions.create!(mailing_list: list)
      get :index, params: {group_id: mitglied.roles.first.group_id, person_id: mitglied.id}
      expect(assigns(:subscribed)).to include(list)
    end
  end

  describe "subscribable_for: :anyone" do
    let!(:list) { Fabricate(:mailing_list, group: groups(:root), subscribable_for: :anyone) }

    it "shows list in subscribable" do
      get :index, params: {group_id: mitglied.roles.first.group_id, person_id: mitglied.id}
      expect(assigns(:subscribable)).to include(list)
    end

    it "shows list when subscribed" do
      mitglied.subscriptions.create!(mailing_list: list)
      get :index, params: {group_id: mitglied.roles.first.group_id, person_id: mitglied.id}
      expect(assigns(:subscribed)).to include(list)
    end

    describe "fundraising" do
      before do
        list.update_column(:internal_key, SacCas::MAILING_LIST_SPENDENAUFRUFE_INTERNAL_KEY)
      end

      it "shows list in subscribable" do
        get :index, params: {group_id: mitglied.roles.first.group_id, person_id: mitglied.id}
        expect(assigns(:subscribable)).to include(list)
      end

      it "hides list when subscribed" do
        mitglied.subscriptions.create!(mailing_list: list)
        get :index, params: {group_id: mitglied.roles.first.group_id, person_id: mitglied.id}
        expect(assigns(:subscribed)).not_to include(list)
      end
    end
  end
end
