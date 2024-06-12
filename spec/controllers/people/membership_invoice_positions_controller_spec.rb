# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe People::MembershipInvoicePositionsController, type: :controller do

  let(:person) { people(:mitglied) }

  before { sign_in(people(:admin)) }

  before do
    SacMembershipConfig.update_all(valid_from: 2015)
    SacSectionMembershipConfig.update_all(valid_from: 2015)
  end

  describe 'GET show' do
    it 'shows positions csv' do
      get :show, params: { group_id: groups(:bluemlisalp_mitglieder).id, id: person.id, date: '2015-03-01' }

      expect(response).to have_http_status(:ok)
      csv = CSV.parse(response.body)
      expect(csv.size).to eq(6)
      expect(csv.second).to eq(["sac_fee", "sac_fee", "40.0", "42", "SAC/CAS"])
      expect(csv.fifth).to eq(["section_fee", nil, "42.0", "98", "SAC Blüemlisalp"])
      expect(csv.map(&:first)).to eq(["name", "sac_fee", "hut_solidarity_fee", "sac_magazine", "section_fee", "section_fee"])
    end
  end

end
