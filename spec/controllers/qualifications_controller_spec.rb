# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe QualificationsController do
  before { sign_in(person) }

  let(:params) { {group_id: person.primary_group.id, person_id: person.id} }
  let(:person) { people(:tourenchef) }

  describe "as tourenchef" do
    context "GET new" do
      it "only renders editable qualification kinds" do
        visible = Fabricate(:qualification_kind, tourenchef_may_edit: true)
        invisible = Fabricate(:qualification_kind, tourenchef_may_edit: false)
        get :new, params: params
        qualification_kinds = assigns(:qualification_kinds)
        expect(qualification_kinds).to include(visible)
        expect(qualification_kinds).to_not include(invisible)
      end
    end
  end

  context "POST create" do
    let(:qualification_params) {
      {qualification: {start_at: "01.03.2024", finish_at: "31.03.2024"}}
    }

    it "ignores finish_at for qualification kinds with validity" do
      qualification_kind_id = Fabricate(:qualification_kind, validity: 2).id

      expect do
        post :create,
          # rubocop:todo Layout/LineLength
          params: params.merge(qualification_params.deep_merge(qualification: {qualification_kind_id: qualification_kind_id}))
        # rubocop:enable Layout/LineLength
      end.to change { Qualification.count }.by(1)

      qualification = person.qualifications.last

      expect(qualification.finish_at).to eq(qualification.start_at.end_of_year + 2.years)
    end

    it "allows finish_at for qualification kinds without validity" do
      qualification_kind_id = Fabricate(:qualification_kind, validity: nil).id

      expect do
        post :create,
          # rubocop:todo Layout/LineLength
          params: params.merge(qualification_params.deep_merge(qualification: {qualification_kind_id: qualification_kind_id}))
        # rubocop:enable Layout/LineLength
      end.to change { Qualification.count }.by(1)

      qualification = person.qualifications.last

      expect(qualification.finish_at).to eq(Date.new(2024, 3, 31))
    end

    it "is invalid when start_at is in the future" do
      qualification_kind_id = Fabricate(:qualification_kind, validity: 2).id
      travel_to Date.new(2024, 1, 1)

      expect do
        post :create,
          # rubocop:todo Layout/LineLength
          params: params.merge(qualification_params.deep_merge(qualification: {qualification_kind_id: qualification_kind_id}))
        # rubocop:enable Layout/LineLength
      end.not_to change { Qualification.count }

      expect(response).not_to be_successful
    end
  end
end
