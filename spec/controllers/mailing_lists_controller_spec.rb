# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe MailingListsController do

  before do
    sign_in(people(:admin))
    allow(controller).to receive(:can?).with(:update, mailing_list, anything).and_return(true)
  end

  context 'PATCH update' do
    let(:mailing_list) { Fabricate(:mailing_list, group: groups(:root)) }
    let(:params) do
      {
        group_id: mailing_list.group_id,
        id: mailing_list.id,
        mailing_list: {
          name: 'new name',
          description: 'new description'
        }
      }
    end

    it 'updates record' do
      expect { patch :update, params: params }.
        to change { mailing_list.reload.name }.to('new name').
        and change { mailing_list.reload.description }.to('new description')
    end

    it 'ignores params if user has no permission' do
      allow(controller).to receive(:can?).with(:update, mailing_list, 'description').and_return(false)

      expect { patch :update, params: params }.
        to change { mailing_list.reload.name }.to('new name').
        and not_change { mailing_list.reload.description }
    end
  end

end
