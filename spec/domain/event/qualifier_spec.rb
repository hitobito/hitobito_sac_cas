# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Event::Qualifier do
  let(:ski_course) { event_kinds(:ski_course) }
  let(:ski_leader) { qualification_kinds(:ski_leader) }
  let(:person) { people(:mitglied) }
  let(:today) { Date.new(2024, 3, 26) }

  describe 'prolonging' do
    let(:participation) { create_course_participation(start_at: today, training_days: 1) }
    subject(:qualifier) { described_class.for(participation) }
    let(:start_dates) { person.qualifications.order(:start_at).pluck(:start_at) }

    it 'does issue if event itself has sufficient training days' do
      create_qualification(today - 1.year)
      participation.event.update!(training_days: 2)
      expect { qualifier.issue }.to change { person.qualifications.count }.by(1)
      expect(start_dates).to eq [today - 1.year, today]
    end

    it 'does issue if event combined with training has sufficient training days' do
      create_qualification(today - 1.year)
      create_external_training(today - 5.months, training_days: 1)
      expect { qualifier.issue }.to change { person.qualifications.count }.by(1)
      expect(start_dates).to eq [today - 1.year, today - 5.months]
    end

    it 'does not issue if qualification date would be earlier than latest qualification' do
      create_qualification(today - 1.year)
      create_external_training(today - 15.months, training_days: 1)
      expect { qualifier.issue }.not_to change { person.qualifications.count }
      expect(start_dates).to eq [today - 1.year]
    end

    it 'does not issue if training is after course qualification date' do
      create_qualification(today - 1.year)
      create_external_training(today + 1.day, training_days: 1)
      expect { qualifier.issue }.not_to change { person.qualifications.count }
      expect(start_dates).to eq [today - 1.year]
    end
  end

  def create_qualification(start_at, qualified_at = start_at)
    Fabricate(:qualification, person: person, qualification_kind: ski_leader, start_at: start_at, qualified_at: qualified_at)
  end

  def create_external_training(start_at, training_days:)
    Fabricate(:external_training_skip_issue_qualifications, {
      person: person,
      event_kind: ski_course,
      start_at: start_at,
      finish_at: start_at,
      training_days: training_days
    })
  end

  def create_course_participation(training_days: nil, start_at:, qualified: false)
    course = Fabricate.build(:course, kind: ski_course, training_days: training_days)
    course.dates.build(start_at: start_at)
    course.save!
    Fabricate(:event_participation, event: course, person: person, qualified: qualified)
  end
end
