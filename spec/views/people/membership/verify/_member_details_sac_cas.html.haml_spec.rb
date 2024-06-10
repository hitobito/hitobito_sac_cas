
require 'spec_helper'

describe 'people/membership/verify/_member_details_sac_cas.html.haml' do
  include FormatHelper

  let(:dom) { render; Capybara::Node::Simple.new(@rendered)  }
  let(:person) { people(:mitglied) }

  before { allow(view).to receive_messages(person: person) }

  context 'active tour guide' do
    it 'renders membership info for active tour guides' do
      person.roles.destroy_all
      person.qualifications.create!(
        qualification_kind: qualification_kinds(:ski_leader),
        start_at: 1.month.ago
      )
      person.roles.create!(
        type: Group::SektionsTourenkommission::Tourenleiter.sti_name,
        group: groups(:matterhorn_tourenkommission)
      )

      expect(dom).to have_text I18n.t('people.membership.verify.member_details_sac_cas.tour_guide')
    end
  end
end
