# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::Event::SacCourseFinances::TotalRevenue do
  before do
    @course1 = Fabricate(:sac_open_course)

    attended1 = create_participation(@course1)
    create_invoice(attended1, total: 125.20)
    create_invoice(attended1, state: :cancelled, total: 155.80) # cancelled invoices are ignored

    attended2 = create_participation(@course1)
    create_invoice(attended2, total: 99.50)

    canceled = create_participation(@course1, state: :canceled, canceled_at: 2.weeks.ago)
    create_invoice(canceled, type: ExternalInvoice::CourseAnnulation, total: 35.00)

    absent = create_participation(@course1, state: :absent)
    create_invoice(absent, total: 133.00)

    @other_course = Fabricate(:sac_open_course)
    other = create_participation(@other_course)
    create_invoice(other, state: :open, total: 119.50)

    @excluded_course = Fabricate(:sac_open_course)
    excluded = create_participation(@excluded_course)
    create_invoice(excluded, total: 100)
  end

  def create_participation(event, state: :attended, **opts)
    Fabricate(:event_participation,
      event: event,
      state: state,
      roles: [Fabricate.build(:"Event::Course::Role::Participant")],
      **opts)
  end

  def create_invoice(participation, total:, type: ExternalInvoice::CourseParticipation, state: :payed)
    type.create!(person: participation.person, state: state, link: participation, total: total)
  end

  it "summarizes rates" do
    course_ids = [@course1.id, @other_course.id]
    expect(described_class.new.fetch(course_ids)).to eq(
      @course1.id => 125.20 + 99.50, # attended 1 + 2
      @other_course.id => 119.5 # other
    )
  end
end
