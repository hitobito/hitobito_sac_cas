#  frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

require "spec_helper"

RSpec.describe PersonResource, type: :resource do
  let(:ability) { Ability.new(people(:admin)) }

  describe "serialization" do
    let(:person) { people(:mitglied) }

    subject(:attributes) { jsonapi_data[0].attributes.symbolize_keys }

    before do
      params[:filter] = {id: {eq: person.id}}
    end

    context "family_id" do
      it "is included" do
        render
        expect(attributes.keys).to include :family_id
      end
    end

    context "membership_number" do
      it "is included if person has anytime membership" do
        roles(:mitglied).update!(end_on: 1.day.ago)
        render
        expect(attributes.keys).to include :membership_number
        expect(attributes[:membership_number]).to eq person.id
      end

      context "without membership" do
        let(:person) { people(:admin) }

        it "is blank" do
          render
          expect(attributes.keys).to include :membership_number
          expect(attributes[:membership_number]).to be_blank
        end
      end
    end

    context "membership_years" do
      it "is not included" do
        render
        expect(attributes.keys).not_to include :membership_years
      end

      it "can be requested" do
        params[:extra_fields] = {people: "membership_years"}
        travel_to(Date.new(2024, 12, 3)) do
          render
        end
        expect(attributes.keys).to include :membership_years

        expected_membership_years = Role.with_membership_years.find(roles(:mitglied).id)
          .membership_years.to_i
        expect(attributes[:membership_years]).to eq expected_membership_years
      end

      context "without membership" do
        let(:person) { people(:admin) }

        it "is blank" do
          render
          expect(attributes[:membership_years]).to be_blank
        end
      end
    end

    context "sac_remarks" do
      it "is included" do
        render
        Person::SAC_REMARKS.each do |remark|
          expect(attributes.keys).to include remark.to_sym
        end
      end
    end
  end
end
