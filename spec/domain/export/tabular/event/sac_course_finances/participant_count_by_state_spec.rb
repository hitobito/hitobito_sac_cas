# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::Event::SacCourseFinances::ParticipantCountByState do
  before do
    @course1 = Fabricate(:sac_open_course)
    create_participation(@course1, role: :"Event::Course::Role::Leader")
    create_participation(@course1)
    create_participation(@course1)
    create_participation(@course1, state: :canceled, canceled_at: 2.weeks.ago)
    create_participation(@course1, state: :absent)

    @other_course = Fabricate(:sac_open_course)
    create_participation(@other_course)

    @excluded_course = Fabricate(:sac_open_course)
    create_participation(@excluded_course)
  end

  def create_participation(event, role: :"Event::Course::Role::Participant", state: :attended, **opts)
    Fabricate(:event_participation,
      event: event,
      state: state,
      roles: [Fabricate.build(role)],
      **opts)
  end

  it "summarizes states" do
    course_ids = [@course1.id, @other_course.id]
    expect(described_class.new.fetch(course_ids)).to eq(
      @course1.id => {attended: 2, absent: 1},
      @other_course.id => {attended: 1}
    )
  end
end
