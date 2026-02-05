# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Migrations::ProlongCourseQualificationsJob do
  before { travel_to(Time.zone.local(2025, 5, 23)) }

  let(:job) { described_class.new }

  let(:course) do
    Fabricate(:sac_open_course,
      kind: event_kinds(:ski_course),
      training_days: 2,
      dates: [
        Fabricate(:event_date,
          start_at: Date.new(2025, 2, 4),
          finish_at: Date.new(2025, 2, 6))
      ])
  end

  let(:quali_kind) { qualification_kinds(:ski_leader) }

  before do
    allow(job).to receive(:event_kind_short_names).and_return(["SLK", "DMY"])

    event_kinds(:slk).event_kind_qualification_kinds.create!(
      qualification_kind: quali_kind,
      category: "prolongation",
      role: "participant"
    )

    @p1 = Fabricate(:person) # with external training
    @et1 = create_external_training(person: @p1)
    # rubocop:todo Layout/LineLength
    pp = Event::Participation.create!(person: @p1, event: course, state: "attended") # leader participation does qualify
    # rubocop:enable Layout/LineLength
    Event::Course::Role::Leader.create!(participation: pp)
    create_quali(@p1, "2020-11-03")

    @p2 = Fabricate(:person) # with course participation
    pp = Event::Participation.create!(person: @p2, event: course, state: "attended")
    Event::Course::Role::Participant.create!(participation: pp)
    create_quali(@p2, "2024-11-03")
    create_quali(@p2, "2025-02-06") # course quali, will be regenerated

    @p3 = Fabricate(:person) # with external training and course participation
    @et3 = create_external_training(person: @p3)
    pp = Event::Participation.create!(person: @p3, event: course, state: "attended")
    Event::Course::Role::Participant.create!(participation: pp)
    create_quali(@p3, "2023-11-08")

    p4 = Fabricate(:person) # with last year external training
    create_external_training(person: p4, start_at: "2024-04-20", finish_at: "2024-04-21")
    create_quali(p4, "2023-11-08")

    p5 = Fabricate(:person) # with non-attended course
    pp = Event::Participation.create!(person: p5, event: course, state: "absent")
    Event::Course::Role::Participant.create!(participation: pp)
    create_quali(p5, "2023-11-08")

    p6 = Fabricate(:person) # external training, but no previous qualification
    create_external_training(person: p6)
  end

  it "finds people with either course or external training" do
    expect(job.people_with_qualifications).to match_array([@p1, @p2, @p3])
  end

  it "prolongs qualifications in correct order" do
    expect(job).to receive(:prolong_qualifications).with(@p1, [@et1])
    expect(job).to receive(:prolong_qualifications).with(@p2, [course])
    expect(job).to receive(:prolong_qualifications).with(@p3, [@et3, course])

    job.perform
  end

  it "creates all qualifications" do
    expect { job.perform }.to change { Qualification.count }.by(3)

    expect(quali_dates(@p1)).to eq(["2020-11-03", "2025-01-16"])
    expect(quali_dates(@p2)).to eq(["2024-11-03", "2025-02-06"])
    expect(quali_dates(@p3)).to eq(["2023-11-08", "2025-01-16", "2025-02-06"])

    expect(@p1.event_participations.first).not_to be_qualified
    expect(@p2.event_participations.first).to be_qualified
    expect(@p3.event_participations.first).to be_qualified
  end

  def quali_dates(person)
    person.qualifications.order(:start_at).pluck(:start_at).map(&:to_s)
  end

  def create_external_training(attrs)
    ExternalTraining.create!(
      attrs.reverse_merge(
        event_kind: event_kinds(:ski_course),
        start_at: "2025-01-15",
        finish_at: "2025-01-16",
        name: "SLK",
        training_days: 2
      )
    )
  end

  def create_quali(person, date)
    person.qualifications.create!(
      qualification_kind: quali_kind,
      start_at: date,
      qualified_at: date
    )
  end
end
