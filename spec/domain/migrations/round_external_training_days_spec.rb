# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Migrations::RoundExternalTrainingDays do
  subject(:migration) { described_class.new }

  # Bypasses validation (not callbacks) so the real qualifier runs once with the invalid
  # value at creation time, like it would have for data entered before this validation existed.
  def create_invalid_external_training(training_days, finish_at: Time.zone.today,
    event_kind: event_kinds(:ski_course), person: people(:mitglied))
    training = Fabricate.build(:external_training, person: person, event_kind: event_kind,
      start_at: finish_at, finish_at: finish_at, training_days: training_days)
    training.save!(validate: false)
    training
  end

  def scheduled_external_training_ids
    Delayed::Job.where("handler like '%ExternalTraining::QualifierIssueJob%'").map do |job|
      job.payload_object.instance_variable_get(:@external_training_id)
    end
  end

  describe "#migrate" do
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
        migration.migrate
        expect(training.reload.training_days).to eq(expected)
      end
    end

    it "does not change training_days that are already a half day multiple" do
      training = create_invalid_external_training(2.5)
      expect { migration.migrate }.not_to change { training.reload.training_days }
    end

    it "updates multiple affected records" do
      training1 = create_invalid_external_training(2.2)
      training2 = create_invalid_external_training(4.7)

      migration.migrate

      expect(training1.reload.training_days).to eq(2.5)
      expect(training2.reload.training_days).to eq(5.0)
    end

    it "does not enqueue a qualifier issue job for unaffected trainings" do
      create_invalid_external_training(5)

      expect { migration.migrate }.not_to change { Delayed::Job.count }
    end

    it "enqueues a qualifier issue job once per person and event_kind, using the earliest " \
      "adjusted training" do
      earlier = create_invalid_external_training(4.7, finish_at: Date.new(2023, 6, 1))
      create_invalid_external_training(2.2, finish_at: Date.new(2024, 6, 1),
        person: earlier.person, event_kind: earlier.event_kind)
      create_invalid_external_training(1.1, finish_at: Date.new(2025, 1, 1),
        person: earlier.person, event_kind: earlier.event_kind)

      expect { migration.migrate }
        .to change { Delayed::Job.where("handler like '%QualifierIssueJob%'").count }.by(1)

      expect(scheduled_external_training_ids).to eq [earlier.id]
    end

    it "enqueues qualifier issue jobs separately per person, each using their own earliest " \
      "adjusted training" do
      mitglied_earliest = create_invalid_external_training(4.7, finish_at: Date.new(2023, 6, 1),
        person: people(:mitglied))
      create_invalid_external_training(2.2, finish_at: Date.new(2024, 6, 1),
        person: people(:mitglied), event_kind: mitglied_earliest.event_kind)

      admin_earliest = create_invalid_external_training(1.1, finish_at: Date.new(2022, 3, 1),
        person: people(:admin))
      create_invalid_external_training(9.3, finish_at: Date.new(2023, 1, 1),
        person: people(:admin), event_kind: admin_earliest.event_kind)

      migration.migrate

      expect(scheduled_external_training_ids).to contain_exactly(
        mitglied_earliest.id, admin_earliest.id
      )
    end

    it "enqueues qualifier issue jobs separately per event_kind, even for the same person" do
      training_a = create_invalid_external_training(2.2, finish_at: Date.new(2024, 1, 1),
        event_kind: event_kinds(:ski_course))
      training_b = create_invalid_external_training(4.7, finish_at: Date.new(2024, 2, 1),
        person: training_a.person, event_kind: event_kinds(:slk))

      migration.migrate

      expect(scheduled_external_training_ids).to contain_exactly(training_a.id, training_b.id)
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

        expect do
          migration.migrate
          Delayed::Worker.new.work_off
        end.to change { person.qualifications.count }.by(1)

        expect(training.reload.training_days).to eq(2.0)
      end

      it "does not prolong the qualification if the corrected training_days still fall short" do
        Fabricate(:qualification, qualification_kind: qualification_kind, person: person,
          start_at: today - 2.years, qualified_at: today - 2.years)
        training = create_invalid_external_training(1.1, finish_at: today, person: person)

        expect do
          migration.migrate
          Delayed::Worker.new.work_off
        end.not_to change { person.qualifications.count }

        expect(training.reload.training_days).to eq(1.5)
      end
    end
  end

  describe "#list_affected_people" do
    it "returns just the header when nothing is affected" do
      create_invalid_external_training(5)

      expect(migration.list_affected_people).to eq "Mitgliedernummer\n"
    end

    it "includes the Mitgliedernummer of a person with an affected training" do
      person = people(:mitglied)
      create_invalid_external_training(2.2, person: person)

      expect(migration.list_affected_people).to eq "Mitgliedernummer\n#{person.id}\n"
    end

    it "lists a person only once even if they have multiple affected trainings" do
      person = people(:mitglied)
      create_invalid_external_training(2.2, person: person, event_kind: event_kinds(:ski_course))
      create_invalid_external_training(4.7, person: person, event_kind: event_kinds(:slk))

      expect(migration.list_affected_people).to eq "Mitgliedernummer\n#{person.id}\n"
    end

    it "lists multiple affected people, ordered by id" do
      mitglied = people(:mitglied)
      admin = people(:admin)
      create_invalid_external_training(2.2, person: mitglied)
      create_invalid_external_training(4.7, person: admin)

      rows = migration.list_affected_people.lines.map(&:chomp)

      expect(rows.first).to eq "Mitgliedernummer"
      expect(rows.drop(1)).to eq [mitglied, admin].sort_by(&:id).map { |p| p.id.to_s }
    end
  end
end
