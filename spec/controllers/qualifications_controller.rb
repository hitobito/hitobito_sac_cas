# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe QualificationsController do

  before { sign_in(person) }
  let(:params) { { group_id: person.primary_group.id, person_id: person.id } }

  describe 'as tourenchef' do
    let(:person) { people(:tourenchef) }

    context 'GET new' do
      it 'only renders editable qualification kinds' do
        visible = Fabricate(:qualification_kind, tourenchef_may_edit: true)
        invisible = Fabricate(:qualification_kind, tourenchef_may_edit: false)
        get :new, params: params
        qualification_kinds = assigns(:qualification_kinds)
        expect(qualification_kinds).to include(visible)
        expect(qualification_kinds).to_not include(invisible)
      end
    end
  end
end
