#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe 'people/membership/verify/_member_details_sac_cas.html.haml' do
  include FormatHelper

  subject(:tour_guide_info) { I18n.t('people.membership.verify.member_details_sac_cas.tour_guide') }
  let(:dom) { render; Capybara::Node::Simple.new(@rendered)  }
  let(:person) { people(:tourenleiter) }

  before { allow(view).to receive_messages(person: person) }

  context 'member' do
    let(:person) { people(:mitglied) }

    it 'hides tour guide info' do
      expect(dom).not_to have_text tour_guide_info
    end
  end

  context 'tour guide' do
    let(:person) { people(:tourenleiter) }

    it 'renders tour guide info for active tour guides' do
      expect(dom).to have_text tour_guide_info
    end
  end
end
