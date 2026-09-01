# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::FitnessRequirement do
  let(:entry) { event_fitness_requirements(:c) }

  it ".list orders entries" do
    expect(described_class.list)
      .to eq(event_fitness_requirements(:a, :b, :c, :d, :e))
  end

  context "validations" do
    it "require presence of label" do
      entry = described_class.new
      expect(entry).not_to be_valid
      expect(entry.errors[:label]).to eq ["muss ausgefüllt werden"]
      expect(entry.errors[:short_label]).to eq ["muss ausgefüllt werden"]
      entry.label = "Hart"
      entry.short_label = "H"
      entry.description = "Steinhart"
      expect(entry).to be_valid
    end

    it "limits short_label to 5 characters" do
      entry.short_label = "ABCDE"
      expect(entry).to be_valid
      entry.short_label = "ABCDEF"
      expect(entry).not_to be_valid
      expect(entry.errors[:short_label]).to eq ["ist zu lang (mehr als 5 Zeichen)"]
    end
  end

  it "#to_s returns the label" do
    expect(entry.to_s).to eq "C - ziemlich anstrengend"
    expect(entry.short_label).to eq "C"
  end

  context "paranoia" do
    it "hard deletes if no associations exist" do
      expect { entry.destroy }
        .to change { described_class.count }.by(-1)
        .and change { Event::FitnessRequirement::Translation.count }.by(-1)
    end

    it "soft deletes if events exist" do
      entry = events(:section_tour).fitness_requirement
      expect { entry.destroy }
        .to change { described_class.count }.by(0)
        .and change { described_class.without_deleted.count }.by(-1)
        .and change { Event::FitnessRequirement::Translation.count }.by(0)
      expect(entry.deleted_at).to be_present
      expect(entry.translations).to be_present
      expect(events(:section_tour).reload.fitness_requirement).to eq(entry)
    end
  end
end
