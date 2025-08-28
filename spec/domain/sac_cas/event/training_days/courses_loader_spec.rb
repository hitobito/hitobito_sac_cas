# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::TrainingDays::CoursesLoader do
  let(:role) { :participant }
  let(:admin) { people(:admin) }
  let(:ski_course) { event_kinds(:ski_course) }
  let(:ski_leader) { qualification_kinds(:ski_leader) }
  let(:ski_pro) { event_kind_qualification_kinds(:ski_pro) }

  let(:end_date) { 1.month.ago }
  let(:start_date) { ski_leader.validity.years.ago }

  subject(:courses) {
    described_class.new(admin.id, role, [ski_leader.id], start_date, end_date).load
  }

  it "is empty without course or external_trainings" do
    expect(courses).to be_empty
  end

  it "excludes courses from participation" do
    create_course_participation(training_days: 1, start_at: start_date + 1.day, qualified: false)
    expect(courses).to be_empty
  end

  it "includes courses from participation" do
    create_course_participation(training_days: 1, start_at: start_date + 1.day, qualified: true)
    expect(courses).to have(1).item
    expect(courses.first.training_days).to eq 1
  end

  it "includes actual_days from participation" do
    create_course_participation(training_days: 1, start_at: start_date + 1.day, qualified: true, actual_days: 0.5)
    expect(courses).to have(1).item
    expect(courses.first.training_days).to eq 0.5
  end

  describe "external trainings" do
    it "includes training inside of validity period" do
      create_external_training(start_date, end_date)
      expect(courses).to have(1).item
    end

    it "orders trainings by start_at descending" do
      first = create_external_training(start_date - 2.day, end_date)
      second = create_external_training(start_date, end_date)
      third = create_external_training(start_date + 1.day, end_date)
      expect(courses.map(&:qualification_date)).to eq [third, second, first].map(&:qualification_date)
    end

    it "includes training starting outside but finishing inside validity period" do
      create_external_training(start_date - 1.day, end_date)
      expect(courses).to have(1).item
    end

    it "includes training starting inside but finishing outside validity period" do
      create_external_training(start_date, end_date + 1.day)
      expect(courses).to have(1).item
    end

    it "excludes training before of validity period" do
      create_external_training(start_date - 2.days, start_date - 1.day)
      expect(courses).to be_empty
    end

    it "excludes training after of validity period" do
      create_external_training(end_date + 1.day, end_date + 2.days)
      expect(courses).to be_empty
    end

    describe "qualification kind filtering" do
      before { create_external_training(start_date, end_date) }

      it "excludes training which qualifies" do
        ski_pro.update!(category: :qualification)
        expect(courses).to be_empty
      end

      it "excludes training which prolongs leader" do
        ski_pro.update!(role: :leader)
        expect(courses).to be_empty
      end
    end
  end

  def create_external_training(start_at, finish_at = start_at, event_kind: nil, person: nil)
    Fabricate(:external_training, {
      person: person || admin,
      event_kind: event_kind || ski_course,
      start_at: start_at,
      finish_at: finish_at
    })
  end

  def create_course_participation(qualified:, start_at:, kind: ski_course, training_days: nil, actual_days: nil)
    course = Fabricate.build(:course, kind: kind, training_days: training_days)
    course.dates.build(start_at: start_at)
    course.save!
    Fabricate(:event_participation, event: course, participant: admin, qualified: qualified, actual_days: actual_days)
  end
end
