# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe ExternalTraining::QualifierIssueJob do
  let(:person) { people(:mitglied) }
  let(:event_kind) { event_kinds(:ski_course) }
  let(:qualification_kind) { qualification_kinds(:ski_leader) }
  let(:training) do
    Fabricate(:external_training, person: person, event_kind: event_kind, training_days: 2)
  end

  subject(:job) { described_class.new([training.id]) }

  it "issues the qualifier for the training's person" do
    qualifier = instance_double(ExternalTrainings::Qualifier, issue: true)
    expect(ExternalTrainings::Qualifier).to receive(:new)
      .with(person, training).and_return(qualifier)

    job.perform
  end

  it "issues the qualifier for each training, ordered by finish_at" do
    later = Fabricate(:external_training, person: person, event_kind: event_kinds(:slk),
      start_at: Date.new(2024, 2, 1), finish_at: Date.new(2024, 2, 1), training_days: 2)
    earlier = Fabricate(:external_training, person: person, event_kind: event_kind,
      start_at: Date.new(2024, 1, 1), finish_at: Date.new(2024, 1, 1), training_days: 2)
    qualifier = instance_double(ExternalTrainings::Qualifier, issue: true)
    allow(ExternalTrainings::Qualifier).to receive(:new).and_return(qualifier)

    described_class.new([later.id, earlier.id]).perform

    expect(ExternalTrainings::Qualifier).to have_received(:new).with(person, earlier).ordered
    expect(ExternalTrainings::Qualifier).to have_received(:new).with(person, later).ordered
  end

  it "prolongs an existing qualification when the training meets the requirement" do
    today = Date.new(2024, 3, 26)
    travel_to(today) do
      Fabricate(:qualification, qualification_kind: qualification_kind, person: person,
        start_at: today - 2.years, qualified_at: today - 2.years)
      training.update_columns(start_at: today, finish_at: today)

      expect { described_class.new([training.id]).perform }
        .to change { person.qualifications.count }.by(1)
    end
  end
end
