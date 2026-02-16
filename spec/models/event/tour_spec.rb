# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Tour do
  subject(:tour) { events(:section_tour) }

  describe "validations" do
    [:disciplines, :target_groups, :technical_requirements,
      :fitness_requirement, :season].each do |attribute|
      it "validates presence of #{attribute} in state ready" do
        allow(tour).to receive(:state).and_return(:ready)
        value = tour.class.reflect_on_association(attribute)&.collection? ? [] : nil
        tour.send(:"#{attribute}=", value)
        expect(tour).not_to be_valid
        expect(tour.errors[attribute]).to eq ["muss ausgefüllt werden"]
      end

      it "does not validate presence of #{attribute} in state draft" do
        tour.state = :draft
        expect(tour).to be_valid
      end
    end
  end

  describe "#default_participation_state" do
    let(:application) { Fabricate.build(:event_application) }
    let(:participation) {
      Fabricate.build(:event_participation, event: tour, application: application)
    }

    subject(:state) { tour.default_participation_state(participation) }

    context "without automatic_assignment" do
      before { tour.automatic_assignment = false }

      it "returns unconfirmed if places are available" do
        expect(state).to eq "unconfirmed"
      end

      it "returns applied if course has no places available" do
        tour.maximum_participants = 2
        tour.participant_count = 2
        expect(state).to eq "applied"
      end

      it "returns assigned for participation without application (=leader)" do
        participation.application = nil
        expect(state).to eq "assigned"
      end
    end

    context "with automatic_assignment" do
      before { tour.automatic_assignment = true }

      it "returns applied if places are available" do
        expect(state).to eq "applied"
      end

      it "returns applied if course has no places available" do
        tour.participant_count = 2
        expect(state).to eq "applied"
      end
    end
  end
end
