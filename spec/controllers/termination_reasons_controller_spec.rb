# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe TerminationReasonsController do
  before { sign_in(person) }

  let(:entry) { Fabricate(:termination_reason, text: "Good reason") }

  describe "with necessary permissions" do
    let(:person) { people(:admin) }

    context "POST #create" do
      it "creates entry" do
        expect do
          post :create, params: {termination_reason: {text: "foo"}}
        end.to change { TerminationReason.count }.by(1)
      end
    end

    context "PATCH #update" do
      it "updates entry" do
        expect do
          patch :update, params: {id: entry.id, termination_reason: {text: "foo"}}
        end.to change { entry.reload.text }.to("foo")
      end
    end

    context "DELETE #destroy" do
      it "deletes entry" do
        entry.save!
        expect do
          delete :destroy, params: {id: entry.id}
        end.to change { TerminationReason.count }.by(-1)
      end

      it "does not delete referenced entry" do
        entry.save!
        expect(TerminationReason.count).to be > 0
        Fabricate(:role, type: Group::Geschaeftsstelle::MitarbeiterLesend.name,
          group: groups(:geschaeftsstelle), person: person, termination_reason: entry)
        expect do
          delete :destroy, params: {id: entry.id}
        end.not_to change { TerminationReason.count }
      end
    end
  end

  describe "without admin permissions" do
    let(:person) { people(:mitglied) }

    context "POST #create" do
      it "creates entry" do
        expect do
          post :create, params: {termination_reason: {text: "foo"}}
        end.to raise_error CanCan::AccessDenied
      end
    end

    context "PATCH #update" do
      it "updates entry" do
        expect do
          patch :update, params: {id: entry.id, termination_reason: {text: "foo"}}
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
