# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Migrations::RoundExternalTrainingDaysToHalfDaysJob do
  let(:job) { described_class.new }

  # Bypasses validation (not callbacks) so the real qualifier runs once with the invalid
  # value at creation time, like it would have for data entered before this validation existed.
  def create_invalid_external_training(training_days, finish_at: Time.zone.today,
    event_kind: event_kinds(:ski_course), person: people(:mitglied))
    training = Fabricate.build(:external_training, person: person, event_kind: event_kind,
      start_at: finish_at, finish_at: finish_at, training_days: training_days)
    training.save!(validate: false)
    training
  end

  {
    0.1 => 0.5,
    10.2 => 10.5,
    9.3 => 9.5,
    3.4 => 3.5,
    12.6 => 13.0,
    7.7 => 8.0,
    9.8 => 10.0,
    4.9 => 5.0
  }.each do |training_days, expected|
    it "rounds up #{training_days} to #{expected}" do
      training = create_invalid_external_training(training_days)
      job.perform
      expect(training.reload.training_days).to eq(expected)
    end
  end

  it "does not change training_days that are already a half day multiple" do
    training = create_invalid_external_training(2.5)
    expect { job.perform }.not_to change { training.reload.training_days }
  end

  it "updates multiple affected records" do
    training1 = create_invalid_external_training(2.2)
    training2 = create_invalid_external_training(4.7)

    job.perform

    expect(training1.reload.training_days).to eq(2.5)
    expect(training2.reload.training_days).to eq(5.0)
  end

  it "does not issue qualifications for unaffected trainings" do
    create_invalid_external_training(5)

    expect(ExternalTrainings::Qualifier).not_to receive(:new)

    job.perform
  end

  it "issues qualifications once per person and event_kind, using the earliest adjusted training" do
    earlier = create_invalid_external_training(4.7, finish_at: Date.new(2023, 6, 1))
    create_invalid_external_training(2.2, finish_at: Date.new(2024, 6, 1),
      person: earlier.person, event_kind: earlier.event_kind)
    create_invalid_external_training(1.1, finish_at: Date.new(2025, 1, 1),
      person: earlier.person, event_kind: earlier.event_kind)

    qualifier = instance_double(ExternalTrainings::Qualifier, issue: true)
    expect(ExternalTrainings::Qualifier).to receive(:new)
      .with(earlier.person, earlier, "participant").once.and_return(qualifier)

    job.perform
  end

  it "issues qualifications separately per person, each using their own earliest adjusted training" do
    mitglied_earliest = create_invalid_external_training(4.7, finish_at: Date.new(2023, 6, 1),
      person: people(:mitglied))
    create_invalid_external_training(2.2, finish_at: Date.new(2024, 6, 1),
      person: people(:mitglied), event_kind: mitglied_earliest.event_kind)

    admin_earliest = create_invalid_external_training(1.1, finish_at: Date.new(2022, 3, 1),
      person: people(:admin))
    create_invalid_external_training(9.3, finish_at: Date.new(2023, 1, 1),
      person: people(:admin), event_kind: admin_earliest.event_kind)

    calls = []
    allow(ExternalTrainings::Qualifier).to receive(:new) do |person, training, role|
      calls << [person, training, role]
      instance_double(ExternalTrainings::Qualifier, issue: true)
    end

    job.perform

    expect(calls).to contain_exactly(
      [people(:mitglied), mitglied_earliest, "participant"],
      [people(:admin), admin_earliest, "participant"]
    )
  end

  it "issues qualifications separately per event_kind, even for the same person" do
    person = people(:mitglied)
    training_a = create_invalid_external_training(2.2, finish_at: Date.new(2024, 1, 1),
      person: person, event_kind: event_kinds(:ski_course))
    training_b = create_invalid_external_training(4.7, finish_at: Date.new(2024, 2, 1),
      person: person, event_kind: event_kinds(:slk))

    calls = []
    allow(ExternalTrainings::Qualifier).to receive(:new) do |qualified_person, training, role|
      calls << [qualified_person, training, role]
      instance_double(ExternalTrainings::Qualifier, issue: true)
    end

    job.perform

    expect(calls).to contain_exactly(
      [person, training_a, "participant"],
      [person, training_b, "participant"]
    )
  end

  describe "with a real qualification" do
    let(:today) { Date.new(2024, 3, 26) }
    let(:person) { people(:mitglied) }
    let(:qualification_kind) { qualification_kinds(:ski_leader) }

    before { travel_to(today) }

    it "prolongs the qualification once the corrected training_days meet the requirement" do
      Fabricate(:qualification, qualification_kind: qualification_kind, person: person,
        start_at: today - 2.years, qualified_at: today - 2.years)
      training = create_invalid_external_training(1.6, finish_at: today, person: person)

      expect { job.perform }.to change { person.qualifications.count }.by(1)

      expect(training.reload.training_days).to eq(2.0)
    end

    it "does not prolong the qualification if the corrected training_days still fall short" do
      Fabricate(:qualification, qualification_kind: qualification_kind, person: person,
        start_at: today - 2.years, qualified_at: today - 2.years)
      training = create_invalid_external_training(1.1, finish_at: today, person: person)

      expect { job.perform }.not_to change { person.qualifications.count }

      expect(training.reload.training_days).to eq(1.5)
    end
  end
end
