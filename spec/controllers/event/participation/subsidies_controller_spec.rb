# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Event::Participation::SubsidiesController do
  before { sign_in(current_user) }

  let(:current_user) { person }
  let(:person) { people(:admin) }
  let(:group) { course.groups.first }
  let(:course) do
    Fabricate(:sac_course, groups: [groups(:root)], applications_cancelable: true).tap do |c|
      c.dates.first.update_columns(start_at: 1.day.from_now)
    end
  end
  let(:participation) { Fabricate(:event_participation, event: course, person: person) }
  let(:params) { { group_id: group.id, event_id: course.id, participation_id: participation.id } }

  describe 'GET#new' do
    render_views

    let(:dom) { Capybara::Node::Simple.new(response.body) }

    it 'raises when unauthorized' do
      sign_in(people(:mitglied))
      expect { get :new, params: params }.to raise_error(CanCan::AccessDenied)
    end

    it 'renders form and cost table' do
      get :new, params: params

      expect(dom).to have_field 'Subvention', checked: false
      expect(dom).to have_text "Total\n1'300.00 CHF"
      expect(dom).not_to have_css  'td', text: '- Subvention'
    end

    it 'assigns attributes and updates table accordingly' do
      get :new, params: params.merge(event_participation: { subsidy: true })

      expect(dom).to have_field 'Subvention', checked: true
      expect(dom).to have_text "Total\n680.00 CHF"
      expect(dom).to have_css  'td', text: '- Subvention'
    end
  end

  describe 'PUT#update' do
    it 'updates particiation and redirects' do
      expect do
        put :update, params: params.merge(event_participation: { subsidy: true })
      end.to change { participation.reload.subsidy }.from(false).to(true)
      expect(response).to redirect_to group_event_participation_path(group, course, participation)
    end

    it 'raises when unauthorized' do
      sign_in(people(:mitglied))
      expect { get :new, params: params }.to raise_error(CanCan::AccessDenied)
    end
  end
end
