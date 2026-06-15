# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Events::Participations::PriceCalculatable do
  before do
    event_participations(:top_mitglied).destroy
  end

  subject(:participation) { Event::Participation.create!(event: event, participant: person) }

  context "course" do
    let(:event) { events(:top_course) }

    describe "#signup_price_category" do
      context "for member" do
        let(:person) { people(:mitglied) }

        it "returns price_member when no subsidy" do
          expect(participation.signup_price_category).to eq :price_member
        end
      end

      context "for non-member" do
        let(:person) { people(:abonnent) }

        it "returns price_regular" do
          expect(participation.signup_price_category).to eq :price_regular
        end
      end
    end

    describe "#signup_price" do
      before { event.price_subsidized = 10 }

      context "for member" do
        let(:person) { people(:mitglied) }

        it "returns price_subsidized when subsidy true" do
          participation.update!(subsidy: true)

          expect(participation.signup_price).to eq event.price_subsidized
        end

        it "returns price_member when subsidy false" do
          expect(participation.signup_price).to eq event.price_member
        end
      end

      context "for non-member" do
        let(:person) { people(:abonnent) }

        it "returns price_regular" do
          expect(participation.signup_price).to eq event.price_regular
        end
      end
    end

    describe "#subsidizable?" do
      before do
        event.price_subsidized = 10
      end

      context "for member" do
        let(:person) { people(:mitglied) }

        it "is subsidizable" do
          expect(participation).to be_subsidizable
        end

        it "is not subsidizable if course does not have price_subsidized" do
          event.price_subsidized = nil

          expect(participation).not_to be_subsidizable
        end
      end

      context "non-member" do
        let(:person) { people(:abonnent) }

        it "is not subsidizable" do
          expect(participation).not_to be_subsidizable
        end
      end
    end
  end

  context "tour" do
    let(:event) { events(:section_tour) }

    describe "#signup_price_category" do
      context "for member" do
        let(:person) { people(:mitglied) }

        it "returns price_special for member in same section" do
          expect(participation.signup_price_category).to eq :price_special
        end

        it "returns price_special for zusatzsektion member in same section" do
          event.update!(groups: [groups(:matterhorn)])

          expect(participation.signup_price_category).to eq :price_special
        end

        it "returns price_member for member in different section" do
          roles(:mitglied_zweitsektion).destroy
          event.update!(groups: [groups(:matterhorn)])

          expect(participation.signup_price_category).to eq :price_member
        end
      end

      context "for non-member" do
        let(:person) { people(:abonnent) }

        it "returns price_regular" do
          expect(participation.signup_price_category).to eq :price_regular
        end
      end
    end

    describe "#signup_price" do
      context "for member" do
        let(:person) { people(:mitglied) }

        it "returns price_special for member in same section" do
          expect(participation.signup_price).to eq event.price_special
        end

        it "returns price_member for member in different section" do
          roles(:mitglied_zweitsektion).destroy
          event.update!(groups: [groups(:matterhorn)])

          expect(participation.signup_price).to eq event.price_member
        end
      end

      context "for non-member" do
        let(:person) { people(:abonnent) }

        it "returns price_regular" do
          expect(participation.signup_price).to eq event.price_regular
        end
      end
    end

    describe "#subsidizable?" do
      let(:person) { people(:mitglied) }

      it "is not subsidizable" do
        expect(participation).not_to be_subsidizable
      end
    end

    describe "#price_category_may_apply?" do
      let(:person) { people(:mitglied) }

      it "is false if price category may not apply for event" do
        event.special_may_apply = false

        expect(participation.price_category_may_apply?).to be_falsey
      end

      it "is true if price category may apply for event" do
        event.special_may_apply = true

        expect(participation.price_category_may_apply?).to be_truthy
      end
    end
  end
end
