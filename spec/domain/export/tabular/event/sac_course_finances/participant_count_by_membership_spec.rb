# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::Event::SacCourseFinances::ParticipantCountByMembership do
  before do
    @course1 = Fabricate(:sac_open_course,
      dates: [Fabricate.build(:event_date, start_at: 4.weeks.ago, finish_at: 3.weeks.ago)])
    course_start_on = @course1.dates.first.start_at

    # leaders are not included
    p1 = create_participation_with_member_role(
      @course1,
      role: :"Event::Course::Role::Leader",
      start_on: 2.years.ago
    )
    # still just counts as member
    create_participation_with_member_role(@course1, start_on: 5.years.ago, end_on: course_start_on)
    # just counts not as member
    create_participation_with_member_role(@course1, start_on: 2.years.ago, end_on: course_start_on - 1.day)
    # just counts as member
    create_participation_with_member_role(@course1, start_on: course_start_on)
    # just counts not as member
    create_participation_with_member_role(@course1, start_on: course_start_on + 1.day)
    # no member role
    create_participation_with_member_role(@course1,
      member_role: :"Group::SektionsNeuanmeldungenNv::Neuanmeldung",
      member_group: groups(:bluemlisalp_neuanmeldungen_nv),
      start_on: 6.month.ago)
    # no role at all
    create_participation(@course1)
    # cancelled participations are ignored
    create_participation_with_member_role(
      @course1,
      state: :canceled,
      canceled_at: 2.weeks.ago,
      start_on: 2.years.ago
    )

    @other_course = Fabricate(:sac_open_course,
      dates: [Fabricate.build(:event_date, start_at: 8.weeks.ago, finish_at: 7.weeks.ago)])
    create_participation_with_member_role(@other_course, start_on: 6.years.ago)
    create_participation(@other_course, participant: p1.person) # same person as in @course1

    @excluded_course = Fabricate(:sac_open_course)
    create_participation_with_member_role(@excluded_course, start_on: 2.years.ago)
  end

  def create_participation(event, role: :"Event::Course::Role::Participant", state: :attended, **opts)
    Fabricate(:event_participation,
      event: event,
      state: state,
      roles: [Fabricate.build(role)],
      **opts)
  end

  def create_participation_with_member_role(
    event,
    role: :"Event::Course::Role::Participant",
    state: :attended,
    member_role: :"Group::SektionsMitglieder::Mitglied",
    member_group: nil,
    start_on: nil,
    end_on: nil,
    **opts
  )
    participation = create_participation(event, state:, role:, **opts)
    member_attrs = {
      person: participation.person,
      group: member_group || groups(:bluemlisalp_mitglieder),
      start_on: start_on
    }
    member_attrs[:end_on] = end_on if end_on
    Fabricate(member_role, **member_attrs)
    participation
  end

  it "summarizes by membership" do
    course_ids = [@course1.id, @other_course.id]
    expect(described_class.new.fetch(course_ids)).to eq(
      @course1.id => {true => 2, false => 4},
      @other_course.id => {true => 2}
    )
  end
end
