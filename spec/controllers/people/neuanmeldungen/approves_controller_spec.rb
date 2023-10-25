# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe People::Neuanmeldungen::ApprovesController do
  before { sign_in(people(:admin)) }

  context 'POST create' do
    let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }

    def send_request
      post :create, params: { group_id: group.id, ids: '1,2,3' }
    end

    it 'calls People::Neuanmeldungen::Approve::call' do
      approver = People::Neuanmeldungen::Approve.new
      expect(People::Neuanmeldungen::Approve).to receive(:new).and_return(approver)
      expect(approver).to receive(:attributes=).with({ group: group, people_ids: [1, 2, 3] })
      expect(approver).to receive(:call)

      send_request
    end

    it 'sets the flash message' do
      send_request

      expect(flash[:notice]).to eq('3 Anmeldungen wurden übernommen')
    end

    it 'redirects to the group people list' do
      send_request

      expect(response).to redirect_to(group_people_path(group_id: group.id))
    end
  end
end
