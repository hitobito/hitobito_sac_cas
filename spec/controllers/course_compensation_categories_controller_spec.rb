# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe CourseCompensationCategoriesController do
  before { sign_in(person) }

  let(:entry) { Fabricate(:course_compensation_category) }

  describe "with necessary permissions" do
    let(:person) { people(:admin) }

    context "POST #create" do
      it "creates entry" do
        expect do
          post :create, params: {course_compensation_category: {short_name: "foo"}}
        end.to change { CourseCompensationCategory.count }.by(1)
      end
    end

    context "PATCH #update" do
      it "updates entry" do
        expect do
          patch :update, params: {id: entry.id, course_compensation_category: {short_name: "foo"}}
        end.to change { entry.reload.short_name }.to("foo")
      end
    end

    context "DELETE #destroy" do
      it "deletes entry" do
        entry.save!
        expect do
          delete :destroy, params: {id: entry.id}
        end.to change { CourseCompensationCategory.count }.by(-1)
      end
    end
  end

  describe "without admin permissions" do
    let(:person) { people(:mitglied) }

    context "POST #create" do
      it "creates entry" do
        expect do
          post :create, params: {course_compensation_category: {short_name: "foo"}}
        end.to raise_error CanCan::AccessDenied
      end
    end

    context "PATCH #update" do
      it "updates entry" do
        expect do
          patch :update, params: {id: entry.id, course_compensation_category: {short_name: "foo"}}
        end.to raise_error CanCan::AccessDenied
      end
    end

    context "DELETE #destroy" do
      it "deletes entry" do
        expect do
          delete :destroy, params: {id: entry.id}
        end.to raise_error CanCan::AccessDenied
      end
    end

    context "GET #index" do
      it "does not list entries" do
        expect do
          get :index
        end.to raise_error CanCan::AccessDenied
      end
    end

    context "GET #show" do
      it "does not show entry" do
        expect do
          get :show, params: {id: entry.id}
        end.to raise_error ActionController::UrlGenerationError
      end
    end
  end
end
