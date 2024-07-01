# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Person::SacRemarksController do
  let(:person) { people(:mitglied) }

  before { sign_in(person) }

  context '#index' do
    context 'as member' do
      it 'is unauthorized' do
        expect do
          get :index, params: { group_id: person.groups.first.id, person_id: person.id }
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  
    context 'as employee or functionary' do
      before do
        person.roles.create!(
          group: groups(:matterhorn_funktionaere),
          type: Group::SektionsFunktionaere::Administration.sti_name
        )
      end

      it 'is authorized' do
        expect do
          get :index, params: { group_id: person.groups.first.id, person_id: person.id }
        end.not_to raise_error
      end
    end
  end

  context '#update' do
    context 'as member' do
      it 'cannot manage national office remark' do
        expect do
          put :update, params: { group_id: person.groups.first.id, person_id: person.id, id: :sac_remark_national_office,
                                 person: { sac_remark_national_office: 'example' }  }
        end.to raise_error(CanCan::AccessDenied)
      end
  
      it 'cannot manage section remarks' do
        expect do
          put :update, params: { group_id: person.groups.first.id, person_id: person.id, id: :sac_remark_section_1,
                                 person: { sac_remark_section_1: 'example' }  }
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'as employee' do
      before do
        person.roles.create!(
          group: groups(:geschaeftsstelle),
          type: Group::Geschaeftsstelle::Mitarbeiter.sti_name
        )
      end

      it 'can manage national office remark' do
        expect do
          put :update, params: { group_id: person.groups.first.id, person_id: person.id, id: :sac_remark_national_office,
                                 person: { sac_remark_national_office: 'example' }  }
        end.to change { person.reload.sac_remark_national_office }.from(nil).to('example')
      end
  
      it 'cannot manage section remarks' do
        expect do
          put :update, params: { group_id: person.groups.first.id, person_id: person.id, id: :sac_remark_section_1,
                                 person: { sac_remark_section_1: 'example' }  }
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'as functionary' do
      before do
        person.roles.create!(
          group: groups(:matterhorn_funktionaere),
          type: Group::SektionsFunktionaere::Administration.sti_name
        )
      end

      it 'can manage section remarks' do
        expect do
          put :update, params: { group_id: person.groups.first.id, person_id: person.id, id: :sac_remark_section_1,
                                 person: { sac_remark_section_1: 'example' }  }
        end.to change { person.reload.sac_remark_section_1 }.from(nil).to('example')
      end
  
      it 'cannot manage national office remark' do
        expect do
          put :update, params: { group_id: person.groups.first.id, person_id: person.id, id: :sac_remark_national_office,
                                 person: { sac_remark_national_office: 'example' }  }
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
