# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Migrations::AdjustQualificationRecordsJob do
  let(:job) { described_class.new }

  let(:quali_kind) { qualification_kinds(:ski_leader) }
  let(:person) { Fabricate(:person) }
  let(:latest_quali) { person.qualifications.order(start_at: :desc).first }
  let(:open_training_days) {
    Qualifications::List.new(person).qualifications.first.open_training_days
  }

  before do
    travel_to("2025-05-01")
    quali_kind.update!(validity: 6, required_training_days: 3)
    event_kinds(:slk).event_kind_qualification_kinds.create!(
      qualification_kind: quali_kind,
      category: "prolongation",
      role: "participant"
    )
  end

  it "includes people with active qualifications" do
    p1 = create_quali(person: Fabricate(:person), start_at: "2012-10-12",
      finish_at: "2028-12-31").person
    _p2 = create_quali(person: Fabricate(:person), start_at: "2010-10-12",
      finish_at: "2024-12-31").person
    infinite_kind = QualificationKind.create!(validity: nil, label: "Infinite")
    _p3 = create_quali(person: Fabricate(:person), qualification_kind: infinite_kind,
      start_at: "2010-10-12").person
    p4 = create_quali(person: Fabricate(:person), start_at: "2019-10-12",
      finish_at: "2025-12-31").person
    create_quali(person: p4, qualification_kind: infinite_kind, start_at: "2012-10-12").person
    expect(job.people_with_active_qualifications).to match_array([p1, p4])
  end

  it "adjusts qualifications if they are longer than the validity" do
    create_quali(start_at: "2010-03-05", finish_at: "2028-12-31")
    expect { job.perform }.to change { person.qualifications.count }.by(1)

    expect(latest_quali.start_at.to_s).to eq("2022-12-31")
    expect(latest_quali.finish_at.to_s).to eq("2028-12-31")
  end

  it "does nothing if qualifications has correct duration" do
    quali1 = create_quali(start_at: "2010-03-05", finish_at: "2028-12-31")
    quali2 = create_quali(start_at: "2022-08-08", finish_at: "2028-12-31")
    expect { job.perform }.not_to change { person.qualifications.count }

    expect(quali1.reload.finish_at.to_s).to eq("2028-12-31")
    expect(quali2.reload.finish_at.to_s).to eq("2028-12-31")
  end

  # rubocop:todo Layout/LineLength
  it "will have 2 open training days if qualification finishes correctly and latest training is after quali start year" do
    # rubocop:enable Layout/LineLength
    create_external_training(start_at: "2025-01-15", finish_at: "2025-01-16", training_days: 1)
    create_external_training(start_at: "2023-08-12", finish_at: "2023-08-13", training_days: 3)
    create_quali(start_at: "2010-03-05", finish_at: "2029-12-31")

    expect { job.perform }.to change { person.qualifications.count }.by(1)

    expect(latest_quali.start_at.to_s).to eq("2023-12-31")
    expect(latest_quali.finish_at.to_s).to eq("2029-12-31")
    expect(open_training_days).to eq(2)
  end

  # rubocop:todo Layout/LineLength
  it "will have 3 open training days if qualification finishes correctly and latest training is in quali start year" do
    # rubocop:enable Layout/LineLength
    create_external_training(start_at: "2023-11-15", finish_at: "2023-11-16", training_days: 1)
    create_external_training(start_at: "2023-08-12", finish_at: "2023-08-13", training_days: 3)
    create_quali(start_at: "2010-03-05", finish_at: "2029-12-31")

    expect { job.perform }.to change { person.qualifications.count }.by(1)

    expect(latest_quali.start_at.to_s).to eq("2023-12-31")
    expect(latest_quali.finish_at.to_s).to eq("2029-12-31")
    expect(open_training_days).to eq(3)
  end

  it "will have 0 open training days if qualification finishes too early" do
    create_external_training(start_at: "2025-01-15", finish_at: "2025-01-16", training_days: 2)
    create_external_training(start_at: "2023-08-12", finish_at: "2023-08-13", training_days: 2)
    create_external_training(start_at: "2020-01-11", finish_at: "2020-01-12", training_days: 2)
    create_quali(start_at: "2010-03-05", finish_at: "2026-12-31")

    expect { job.perform }.to change { person.qualifications.count }.by(1)

    expect(latest_quali.start_at.to_s).to eq("2020-12-31")
    expect(latest_quali.finish_at.to_s).to eq("2026-12-31")
    expect(open_training_days).to eq(0)
  end

  # rubocop:todo Layout/LineLength
  it "will have 3 open training days if qualification finishes too late and latest training is in quali start year" do
    # rubocop:enable Layout/LineLength
    create_external_training(start_at: "2024-01-15", finish_at: "2024-01-16", training_days: 2)
    create_external_training(start_at: "2023-08-12", finish_at: "2023-08-13", training_days: 2)
    create_quali(start_at: "2010-03-05", finish_at: "2030-12-31")

    expect { job.perform }.to change { person.qualifications.count }.by(1)

    expect(latest_quali.start_at.to_s).to eq("2024-12-31")
    expect(latest_quali.finish_at.to_s).to eq("2030-12-31")
    expect(open_training_days).to eq(3)
  end

  # rubocop:todo Layout/LineLength
  it "will have 1 open training days if qualification finishes too late and latest training is after quali start year" do
    # rubocop:enable Layout/LineLength
    create_external_training(start_at: "2024-01-15", finish_at: "2024-01-16", training_days: 1)
    create_external_training(start_at: "2023-08-12", finish_at: "2023-08-13", training_days: 1)
    create_external_training(start_at: "2020-01-12", finish_at: "2020-01-13", training_days: 1)
    create_quali(start_at: "2010-03-05", finish_at: "2028-12-31")

    expect { job.perform }.to change { person.qualifications.count }.by(1)

    expect(latest_quali.start_at.to_s).to eq("2022-12-31")
    expect(latest_quali.finish_at.to_s).to eq("2028-12-31")
    expect(open_training_days).to eq(1)
  end

  def create_external_training(attrs)
    ExternalTraining.create!(
      attrs.reverse_merge(
        person: person,
        event_kind: event_kinds(:ski_course),
        start_at: "2025-01-15",
        finish_at: "2025-01-16",
        name: "SLK",
        training_days: 2
      )
    )
  end

  def create_quali(attrs)
    Qualification
      .create!(attrs.reverse_merge(person: person, qualification_kind: quali_kind))
      .tap { |q| q.update_column(:finish_at, attrs.fetch(:finish_at)) if attrs.key?(:finish_at) }
  end
end
