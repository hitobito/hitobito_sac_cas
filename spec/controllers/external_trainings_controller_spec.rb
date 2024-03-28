# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe ExternalTrainingsController do

  let(:person) { people(:mitglied) }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:ski_course) { event_kinds(:ski_course) }
  let(:ski_leader) { qualification_kinds(:ski_leader) }
  let(:start_at) { Date.new(2024, 1, 1) }

  before { sign_in(people(:admin)) }

  describe 'POST#create' do
    let(:ski_leader_qualis) { person.qualifications.where(qualification_kind: ski_leader) }
    let(:params) {
      {
        group_id: group.id,
        person_id: person.id,
        external_training: {
          event_kind_id: ski_course.id,
          start_at: start_at,
          finish_at: start_at,
          training_days: 1,
          name: 'Skikurs'
        }
      }
    }

    it 'creates training without qualification' do
      expect do
        post :create, params: params
        expect(response).to redirect_to(history_group_person_path(group, person))
      end.to change { ExternalTraining.count }.by(1)
        .and not_change { Qualification.count }
    end

    it 'creates qualification if event qualifies' do
      create_event_kind_quali_kind(ski_course, ski_leader, category: :qualification)
      expect do
        post :create, params: params
      end.to change { ski_leader_qualis.count }.by(1)
    end

    context 'existing qualification' do
      let!(:quali) do
        Fabricate(:qualification, qualification_kind: ski_leader, person: person, start_at: 3.years.ago, qualified_at: 3.years.ago)
      end

      it 'prolongs qualification if criteria matches' do
        ski_leader.update!(required_training_days: nil)
        expect do
          post :create, params: params
        end.to change { ski_leader_qualis.count }.by(1)
      end

      it 'noops if qualification is too old' do
        quali.update_columns(finish_at: Date.new(2015, 1, 1))
        expect do
          post :create, params: params
        end.not_to change { ski_leader_qualis.count }
      end

      context 'training days' do
        it 'prolongs qualification if training has enough training days' do
          expect do
            post :create, params: params.deep_merge(external_training: { training_days: 2 })
          end.to change { ski_leader_qualis.count }
        end

        it 'noops if training has not enough training days' do
          expect do
            post :create, params: params.deep_merge(external_training: { training_days: 1.5 })
          end.to not_change { ski_leader_qualis.count }
        end
      end
    end
  end

  describe 'POST#destroy' do
    let(:ski_leader_qualis) { person.qualifications.where(qualification_kind: ski_leader) }
    let(:params) { { group_id: group.id, person_id: person.id, id: training.id } }
    let!(:training) { Fabricate(:external_training, person: person) }

    before { create_event_kind_quali_kind(ski_course, ski_leader) }

    it 'removes training' do
      expect do
        delete :destroy, params: params
        expect(response).to redirect_to(history_group_person_path(group, person))
      end.to change { ExternalTraining.count }.by(-1)
    end

    it 'removes training and corresponding  qualification' do
      qualification = Fabricate(:qualification, qualification_kind: ski_leader, person: person, qualified_at: training.finish_at)

      expect do
        delete :destroy, params: params
        expect(response).to redirect_to(history_group_person_path(group, person))
      end.to change { ExternalTraining.count }.by(-1)
        .and change { Qualification.count }.by(-1)
    end
  end

  def create_event_kind_quali_kind(event_kind, quali_kind, category: :qualification)
    Event::KindQualificationKind.create!(
      event_kind: event_kind,
      qualification_kind: quali_kind,
      category: category,
      role: :participant
    )
  end
end
