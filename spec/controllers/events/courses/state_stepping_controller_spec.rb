# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Events::Courses::StateSteppingController do

  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:group) { groups(:root) }
  let(:course) { events(:closed).tap { _1.update!(state: 'created') } }

  describe 'PUT#update' do
    context 'as mitglied' do
      before { sign_in(mitglied) }

      it 'is unauthorized' do
        expect do
          put :update, params: { group_id: group.id, id: course.id, state: 'application_open' }
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'as admin' do
      before { sign_in(admin) }

      it 'updates state if step is possible' do
        put :update, params: { group_id: group.id, id: course.id, state: 'application_open' }

        course.reload

        expect(flash[:notice]).to eq('Status wurde auf Publiziert gesetzt.')

        expect(course.state).to eq('application_open')
        expect(response).to redirect_to(group_event_path(group, course))
      end

      it 'does not update state if step is impossible' do
        expect(course).to_not receive(:state=)

        put :update, params: { group_id: group.id, id: course.id, state: 'ready' }

        expect(course.state).to eq('created')
        expect(response).to redirect_to(group_event_path(group, course))
      end

      it 'does not update state if step makes event invalid' do
        course = events(:top_course)

        put :update, params: { group_id: group.id, id: course.id, state: 'application_open' }

        course.reload

        expect(course.state).to eq('created')
        expect(response).to redirect_to(group_event_path(group, course))
      end
    end
  end
end
