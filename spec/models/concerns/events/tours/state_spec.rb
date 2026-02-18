# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Events::Tours::State do
  shared_examples "state validations" do |current_state, possible_states, invalid_states|
    subject(:model) {
      Fabricate(:sac_tour, state: current_state,
        disciplines: [event_disciplines(:wandern)],
        target_groups: [event_target_groups(:kinder)],
        technical_requirements: [event_technical_requirements(:klettern)],
        fitness_requirement: event_fitness_requirements(:a),
        season: "Sommer")
    }

    possible_states.each do |state|
      it "#{state} is valid next state for #{current_state}" do
        subject.state = state
        expect(subject).to be_valid
      end
    end

    invalid_states.each do |state|
      it "#{state} is not valid next state for #{current_state}" do
        subject.state = state
        expect(subject).not_to be_valid
      end
    end

    it "non existent state is not valid next state" do
      subject.state = :this_state_should_never_exist
      expect(subject).not_to be_valid
    end
  end

  it_behaves_like "state validations", :draft, [:review, :approved], [:published, :ready, :closed, :canceled]
  it_behaves_like "state validations", :review, [:draft, :approved], [:published, :ready, :closed, :canceled]
  it_behaves_like "state validations", :approved, [:draft, :published, :canceled], [:review, :ready, :closed]
  it_behaves_like "state validations", :published, [:draft, :approved, :ready, :canceled], [:review, :closed]
  it_behaves_like "state validations", :ready, [:published, :closed, :canceled], [:draft, :review, :approved]
  it_behaves_like "state validations", :closed, [:ready], [:draft, :review, :approved, :published, :canceled]
  it_behaves_like "state validations", :canceled, [:approved, :published, :ready], [:draft, :review, :closed]
end
