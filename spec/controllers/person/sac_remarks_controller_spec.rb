# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Person::SacRemarksController do
  let(:person) { people(:mitglied) }
  let(:group_id) { person.groups.first.id }

  before { sign_in(person) }

  context "#index" do
    context "as member" do
      it "is unauthorized" do
        expect do
          get :index, params: {group_id: group_id, person_id: person.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as employee" do
      before do
        person.roles.create!(
          group: groups(:geschaeftsstelle),
          type: Group::Geschaeftsstelle::Mitarbeiter.sti_name
        )
      end

      it "is authorized" do
        get :index, params: {group_id: group_id, person_id: person.id}
        expect(response).to have_http_status(:success)
      end
    end

    context "as functionary" do
      before do
        person.roles.create!(
          group: groups(:matterhorn_funktionaere),
          type: Group::SektionsFunktionaere::Administration.sti_name
        )
      end

      it "is authorized" do
        get :index, params: {group_id: group_id, person_id: person.id}
        expect(response).to have_http_status(:success)
      end
    end
  end

  context "#edit" do
    context "as member" do
      it "cannot edit national office remark" do
        expect do
          get :edit, params: {group_id: group_id, person_id: person.id, id: :sac_remark_national_office}
        end.to raise_error(CanCan::AccessDenied)
      end

      it "cannot edit section remarks" do
        expect do
          get :edit, params: {group_id: group_id, person_id: person.id, id: :sac_remark_section_1}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as employee" do
      before do
        person.roles.create!(
          group: groups(:geschaeftsstelle),
          type: Group::Geschaeftsstelle::Mitarbeiter.sti_name
        )
      end

      it "can edit national office remark" do
        get :edit, params: {group_id: group_id, person_id: person.id, id: :sac_remark_national_office}
        expect(response).to have_http_status(:success)
      end

      it "cannot edit section remarks" do
        expect do
          get :edit, params: {group_id: group_id, person_id: person.id, id: :sac_remark_section_1}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as functionary" do
      before do
        person.roles.create!(
          group: groups(:matterhorn_funktionaere),
          type: Group::SektionsFunktionaere::Administration.sti_name
        )
      end

      it "can edit section remarks" do
        get :edit, params: {group_id: group_id, person_id: person.id, id: :sac_remark_section_1}
        expect(response).to have_http_status(:success)
      end

      it "cannot edit national office remark" do
        expect do
          get :edit, params: {group_id: group_id, person_id: person.id, id: :sac_remark_national_office}
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  context "#update" do
    context "as member" do
      it "cannot manage national office remark" do
        expect do
          put :update, params: {group_id: group_id, person_id: person.id, id: :sac_remark_national_office,
                                person: {sac_remark_national_office: "example"}}
        end.to raise_error(CanCan::AccessDenied)
      end

      it "cannot manage section remarks" do
        expect do
          put :update, params: {group_id: group_id, person_id: person.id, id: :sac_remark_section_1,
                                person: {sac_remark_section_1: "example"}}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as employee" do
      before do
        person.roles.create!(
          group: groups(:geschaeftsstelle),
          type: Group::Geschaeftsstelle::Mitarbeiter.sti_name
        )
      end

      it "can manage national office remark" do
        expect do
          put :update, params: {group_id: group_id, person_id: person.id, id: :sac_remark_national_office,
                                person: {sac_remark_national_office: "example"}}
        end.to change { person.reload.sac_remark_national_office }.from(nil).to("example")
      end

      it "cannot manage section remarks" do
        expect do
          put :update, params: {group_id: group_id, person_id: person.id, id: :sac_remark_section_1,
                                person: {sac_remark_section_1: "example"}}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as functionary" do
      before do
        person.roles.create!(
          group: groups(:matterhorn_funktionaere),
          type: Group::SektionsFunktionaere::Administration.sti_name
        )
      end

      it "can manage section remarks" do
        expect do
          put :update, params: {group_id: group_id, person_id: person.id, id: :sac_remark_section_1,
                                person: {sac_remark_section_1: "example"}}
        end.to change { person.reload.sac_remark_section_1 }.from(nil).to("example")
      end

      it "cannot manage national office remark" do
        expect do
          put :update, params: {group_id: group_id, person_id: person.id, id: :sac_remark_national_office,
                                person: {sac_remark_national_office: "example"}}
        end.to raise_error(CanCan::AccessDenied)
      end

      it "cannot update attributes other than remarks" do
        expect do
          put :update, params: {group_id: group_id, person_id: person.id, id: :first_name,
                                person: {first_name: "example"}}
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
