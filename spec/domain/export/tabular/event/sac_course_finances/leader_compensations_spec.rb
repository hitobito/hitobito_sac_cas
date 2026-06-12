# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::Event::SacCourseFinances::LeaderCompensations do
  before do
    @cat1 = Fabricate(:course_compensation_category, leader_settlement: true, kind: :day)
    @rate1 = create_compensation_rate(@cat1, 50, 45, 30, 25, valid_from: "2020-01-01")

    @cat2 = Fabricate(:course_compensation_category, leader_settlement: true, kind: :day)
    @rate21 = create_compensation_rate(@cat2, 59, 54, 39, 34, valid_from: "2020-01-01", valid_to: "2023-12-31")
    @rate22 = create_compensation_rate(@cat2, 60, 55, 40, 35, valid_from: "2024-01-01", valid_to: "2024-12-31")
    @rate23 = create_compensation_rate(@cat2, 62, 57, 42, 37, valid_from: "2025-01-01")

    @cat_other_kind = Fabricate(:course_compensation_category, leader_settlement: true, kind: :day)
    @rate_other_kind = create_compensation_rate(@cat_other_kind, 55, 50, 35, 30, valid_from: "2020-01-01")

    @cat_not_settlement = Fabricate(:course_compensation_category, leader_settlement: false, kind: :day)
    @rate_not_settlement = create_compensation_rate(@cat_not_settlement, 52, 47, 32, 27, valid_from: "2020-01-01")

    @cat_excluded = Fabricate(:course_compensation_category, leader_settlement: true, kind: :day)
    @rate_excluded = create_compensation_rate(@cat_excluded, 53, 48, 33, 28, valid_from: "2020-01-01")

    @kind = Fabricate(:sac_event_kind, course_compensation_categories: [@cat1, @cat2])
    @other_kind = Fabricate(:sac_event_kind, course_compensation_categories: [@cat_other_kind, @cat_not_settlement])
    @kind_excluded = Fabricate(:sac_event_kind, course_compensation_categories: [@cat_excluded, @cat_not_settlement])

    @course1 = Fabricate(:sac_open_course,
      kind: @kind,
      dates_attributes: [
        {start_at: "2024-05-01", finish_at: "2024-05-05"},
        {start_at: "2025-01-10", finish_at: "2025-01-18"} # is not used for rate
      ])
    create_participation(@course1, actual_days: 5, roles: [:"Event::Course::Role::Leader"])
    create_participation(@course1, actual_days: 4, roles: [:"Event::Course::Role::AssistantLeader"])

    @other_course = Fabricate(:sac_open_course,
      kind: @other_kind,
      dates_attributes: [{start_at: "2024-06-01", finish_at: "2024-06-04"}])
    create_participation(@other_course,
      actual_days: 3,
      roles: [
        :"Event::Course::Role::LeaderAspirant",
        :"Event::Course::Role::AssistantLeader" # assistant leader will be used before leader aspirant
      ])

    @excluded_course = Fabricate(:sac_open_course,
      kind: @kind,
      dates_attributes: [{start_at: "2024-07-01", finish_at: "2024-07-08"}])
    create_participation(@excluded_course, actual_days: 2, roles: [:"Event::Course::Role::AssistantLeader"])
  end

  def create_compensation_rate(category, leader, assistant_leader, leader_aspirant, assistant_leader_aspirant,
    valid_from:, valid_to: nil)
    category.course_compensation_rates.create!(
      rate_leader: leader,
      rate_assistant_leader: assistant_leader,
      rate_leader_aspirant: leader_aspirant,
      rate_assistant_leader_aspirant: assistant_leader_aspirant,
      valid_from: valid_from,
      valid_to: valid_to
    )
  end

  def create_participation(event, actual_days:, roles: [:"Event::Course::Role::Participant"])
    Fabricate(:event_participation,
      event: event,
      actual_days: actual_days,
      roles: roles.map { Fabricate.build(_1) })
  end

  it "summarizes rates" do
    course_ids = [@course1.id, @other_course.id]
    expect(described_class.new.fetch(course_ids)).to eq(
      @course1.id => 5 * (50 + 60) + 4 * (45 + 55), # rate1 + rate22, leader + assistant_leader
      @other_course.id => 3 * 50 # rate_other_kind
    )
  end
end
