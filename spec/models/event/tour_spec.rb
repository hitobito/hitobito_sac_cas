# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Tour do
  subject(:tour) { events(:section_tour) }

  describe "validations" do
    shared_examples "presence validation for draft attributes" do |attribute:, association: false|
      it "validates presence of #{attribute} in state ready" do
        tour.state = :draft
        tour.send(:"#{attribute}=", (association ? [] : nil))
        tour.state = :review
        expect(tour).not_to be_valid
        expect(tour.errors[attribute]).to eq ["muss ausgefüllt werden"]
      end

      it "does not validate presence of #{attribute} in state draft" do
        tour.state = :draft
        expect(tour).to be_valid
      end
    end

    shared_examples "readonly for draft attributes" do |attribute:|
      it "#{attribute} is readonly in state review" do
        tour.update!(state: :review)
        tour.send(:"#{attribute}=", new_valid_value)
        tour.save!
        expect(tour.reload.send(attribute)).not_to eq new_valid_value
      end

      it "#{attribute} is not readonly in state draft" do
        tour.update!(state: :draft)
        tour.send(:"#{attribute}=", new_valid_value)
        tour.save!
        expect(tour.reload.send(attribute)).to eq new_valid_value
      end
    end

    describe "subito" do
      let(:new_valid_value) { false }

      it_behaves_like "readonly for draft attributes", attribute: :subito
    end

    describe "season" do
      let(:new_valid_value) { "Winter" }

      it_behaves_like "presence validation for draft attributes", attribute: :season
      it_behaves_like "readonly for draft attributes", attribute: :season
    end

    describe "fitness requirement" do
      let(:new_valid_value) { event_fitness_requirements(:e) }

      it_behaves_like "presence validation for draft attributes", attribute: :fitness_requirement
      it_behaves_like "readonly for draft attributes", attribute: :fitness_requirement
    end

    describe "disciplines" do
      let(:new_valid_value) { [event_disciplines(:indoorklettern)] }

      it_behaves_like "presence validation for draft attributes", attribute: :disciplines, association: true
      it_behaves_like "readonly for draft attributes", attribute: :disciplines
    end

    describe "target_groups" do
      let(:new_valid_value) { [event_target_groups(:familien)] }

      it_behaves_like "presence validation for draft attributes", attribute: :target_groups, association: true
      it_behaves_like "readonly for draft attributes", attribute: :target_groups
    end

    describe "technical_requirements" do
      let(:new_valid_value) { [event_technical_requirements(:klettern_9a)] }

      it_behaves_like "presence validation for draft attributes", attribute: :technical_requirements, association: true
      it_behaves_like "readonly for draft attributes", attribute: :technical_requirements
    end

    [:duration_h, :duration_m].each do |attr|
      describe attr do
        it "is valid" do
          is_expected.to be_valid
        end

        it "does not allow more than two digits" do
          tour.send(:"#{attr}=", 123)
          is_expected.not_to be_valid

          tour.send(:"#{attr}=", 12.3)
          is_expected.not_to be_valid

          tour.send(:"#{attr}=", 12)
          is_expected.to be_valid

          tour.send(:"#{attr}=", 1)
          is_expected.to be_valid
        end

        it "allows nil" do
          tour.send(:"#{attr}=", nil)

          is_expected.to be_valid
        end
      end
    end

    [:alternative_route, :additional_info, :price_description].each do |attr|
      it "translates #{attr}" do
        tour.send(:"#{attr}_de=", "ja ja")
        tour.send(:"#{attr}_fr=", "Qui qui")

        I18n.locale = :de
        expect(tour.send(attr)).to eq "ja ja"

        I18n.locale = :fr
        expect(tour.send(attr)).to eq "Qui qui"
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

  context "paper trails", versioning: true do
    before do
      tour.update_column(:state, :draft)
    end

    it "sets main to event on discipline create" do
      expect do
        tour.disciplines << event_disciplines(:wandern)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on discipline remove" do
      expect do
        tour.disciplines.destroy_all
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("removed")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on target_group create" do
      expect do
        tour.target_groups << event_target_groups(:senioren)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on target_group remove" do
      expect do
        tour.target_groups.destroy_all
      end.to change { PaperTrail::Version.count }.by(2) # tour fixture had two target_groups

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("removed")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on technical_requirement create" do
      expect do
        tour.technical_requirements << event_technical_requirements(:singletrail)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on technical_requirement remove" do
      expect do
        tour.technical_requirements.destroy_all
      end.to change { PaperTrail::Version.count }.by(2) # tour fixture had two technical_requirements

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("removed")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on trait create" do
      expect do
        tour.traits << event_traits(:training)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on trait remove" do
      expect do
        tour.traits.destroy_all
      end.to change { PaperTrail::Version.count }.by(2) # tour fixture had two traits

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("removed")
      expect(version.main).to eq(tour)
    end
  end
end
