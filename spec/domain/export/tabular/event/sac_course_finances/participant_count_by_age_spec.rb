# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::Event::SacCourseFinances::ParticipantCountByAge do
  before do
    @course1 = Fabricate(:sac_open_course,
      dates: [Fabricate.build(:event_date, start_at: 4.weeks.ago, finish_at: 3.weeks.ago)])
    create_participation(@course1, role: :"Event::Course::Role::Leader", birthday: 45.years.ago)
    p1 = create_participation(@course1, birthday: 4.weeks.ago - 18.years - 2.weeks)
    create_participation(@course1, birthday: 4.weeks.ago - 23.years + 1.day) # still 22
    create_participation(@course1, birthday: 4.weeks.ago - 18.years) # just 18
    create_participation(@course1, state: :canceled, canceled_at: 2.weeks.ago, birthday: 33.years.ago)

    @other_course = Fabricate(:sac_open_course,
      dates: [Fabricate.build(:event_date, start_at: 8.weeks.ago, finish_at: 7.weeks.ago)])
    create_participation(@other_course, birthday: 50.years.ago)
    create_participation(@other_course, participant: p1.person)

    @excluded_course = Fabricate(:sac_open_course,
      dates: [Fabricate.build(:event_date, start_at: 21.weeks.ago, finish_at: 20.weeks.ago)])
    create_participation(@excluded_course, birthday: 20.years.ago)
  end

  def create_participation(event, role: :"Event::Course::Role::Participant", state: :attended, birthday: nil, **opts)
    Fabricate(:event_participation,
      event: event,
      state: state,
      roles: [Fabricate.build(role)],
      **opts).tap { |p| p.person.update!(birthday: birthday) if birthday }
  end

  it "summarizes age groups" do
    course_ids = [@course1.id, @other_course.id]
    expect(described_class.new.fetch(course_ids)).to eq(
      @course1.id => {age_18_22: 3},
      @other_course.id => {age_0_17: 1, age_36_50: 1}
    )
  end

  it "ignores participants without a birthday" do
    p = create_participation(@course1, birthday: 20.years.ago)
    p.person.update!(birthday: nil)

    course_ids = [@course1.id]
    expect(described_class.new.fetch(course_ids)).to eq(
      @course1.id => {age_18_22: 3}
    )
  end
end
