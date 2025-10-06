# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe GroupsController do
  before { sign_in(people(:admin)) }

  let(:group) { groups(:bluemlisalp) }

  context "POST#create" do
    let(:attrs) {
      {
        parent_id: Group.root.id,
        type: Group::Sektion.sti_name,
        name: "Emmental",
        foundation_year: "2000",
        section_canton: "BE"
      }
    }

    it "can create without phone_numbers" do
      expect do
        post :create, params: {group: attrs.merge({
          phone_number_landline_attributes: {number: ""},
          phone_number_mobile_attributes: {number: ""}
        })}
      end.to change { Group::Sektion.count }.by(1)
    end

    it "can create with phone_numbers" do
      expect do
        post :create, params: {group: attrs.merge({
          phone_number_landline_attributes: {number: "0345678901"},
          phone_number_mobile_attributes: {number: "0761234567"}
        })}
      end.to change { Group::Sektion.count }.by(1)
    end
  end

  context "PUT#update" do
    it "can update phone_numbers" do
      expect do
        put :update, params: {id: group.id,
                              group: {
                                phone_number_landline_attributes: {number: "+41 77 123 45 66"},
                                phone_number_mobile_attributes: {number: "+41 77 123 45 67"}
                              }}
      end.to change { group.reload.phone_numbers.count }.by(2)
        .and change { group.phone_number_landline&.number }.to("+41 77 123 45 66")
        .and change { group.phone_number_mobile&.number }.to("+41 77 123 45 67")
    end

    it "can remove phone_numbers" do
      group.create_phone_number_landline(number: "+41 77 123 45 66")

      expect do
        put :update, params: {id: group.id,
                              group: {
                                phone_number_landline_attributes: {
                                  id: group.phone_number_landline.id,
                                  number: ""
                                }
                              }}
      end.to change { group.reload.phone_numbers.count }.by(-1)
        .and change { group.phone_number_landline&.number }.from("+41 77 123 45 66").to(nil)
    end
  end
end
