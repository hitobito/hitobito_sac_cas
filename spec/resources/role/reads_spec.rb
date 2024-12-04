# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

RSpec.describe RoleResource, type: :resource do
  let(:ability) { Ability.new(people(:admin)) }

  describe "serialization" do
    let(:role) { roles(:familienmitglied) }

    subject(:attributes) { jsonapi_data[0].attributes.symbolize_keys }

    before { params[:filter] = {id: {eq: role.id}} }

    context "membership_years" do
      it "is not included" do
        render
        expect(attributes.keys).not_to include :membership_years
      end

      it "can be requested" do
        params[:extra_fields] = {roles: "membership_years"}
        render
        expect(attributes.keys).to include :membership_years
        expect(attributes[:membership_years]).not_to be_blank
      end

      context "without membership" do
        let(:role) { roles(:admin) }

        it "is blank" do
          render
          expect(attributes[:membership_years]).to be_blank
        end
      end
    end
  end
end
