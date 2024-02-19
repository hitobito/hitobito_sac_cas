# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Group::SacCas do
  let(:group) { groups(:root) }

  context 'validations' do
    context 'sac_newsletter_mailing_list_id' do

      it 'allows empty value' do
        expect(group).to be_valid
      end

      it 'allows value of group mailing_list' do
        list = Fabricate(:mailing_list, group: group)
        group.sac_newsletter_mailing_list_id = list.id
        expect(group).to be_valid
      end

      it 'does not allow value from other groups' do
        list = Fabricate(:mailing_list, group: groups(:geschaeftsstelle))
        group.sac_newsletter_mailing_list_id = list.id
        expect(group).not_to be_valid
        expect(group).to have(1).error_on(:sac_newsletter_mailing_list_id)
      end
    end
  end
end
