# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::Event::SacCourseFinances::ParticipantCountByPrice do
  before do
    @course1 = Fabricate(:sac_open_course)
    create_participation(@course1, role: :"Event::Course::Role::Leader")
    create_participation(@course1, price_category: "price_regular")
    create_participation(@course1, price_category: "price_member")
    create_participation(@course1, state: :canceled, canceled_at: 2.weeks.ago, price_category: "price_regular")
    create_participation(@course1, state: :absent, price_category: "price_special")

    @other_course = Fabricate(:sac_open_course)
    create_participation(@other_course, price_category: "price_regular")

    @excluded_course = Fabricate(:sac_open_course)
    create_participation(@excluded_course, price_category: "price_regular")
  end

  def create_participation(event, role: :"Event::Course::Role::Participant", state: :attended, **opts)
    Fabricate(:event_participation,
      event: event,
      state: state,
      roles: [Fabricate.build(role)],
      **opts)
  end

  it "summarizes price categories" do
    course_ids = [@course1.id, @other_course.id]
    expect(described_class.new.fetch(course_ids)).to eq(
      @course1.id => {price_regular: 1, price_member: 1},
      @other_course.id => {price_regular: 1}
    )
  end
end
