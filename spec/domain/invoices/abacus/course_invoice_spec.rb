# frozen_string_literal: true

require "spec_helper"

describe Invoices::Abacus::CourseInvoice do
  let(:mitglied) { people(:mitglied) }
  let(:kind) { event_kinds(:ski_course) }
  let(:course) { Fabricate(:sac_course, kind: kind) }
  let(:participation) { Fabricate(:event_participation, event: course, person: mitglied, price: 20, price_category: 1) }

  subject { described_class.new(participation) }

  before do
    course.dates.destroy_all
    Event::Date.create!(event: course, start_at: "01.01.2024", finish_at: "31.01.2024")
    Event::Date.create!(event: course, start_at: "01.03.2024", finish_at: "31.03.2024")
    participation.reload
  end

  context "#invoice?" do
    it "is true when course price is present" do
      expect(subject.invoice?).to be(true)
    end

    it "is false when course price is nil" do
      participation.update!(price_category: nil, price: nil)

      expect(subject.invoice?).to be(false)
    end
  end

  context "#position" do
    it "creates position with correct values" do
      position = subject.positions.first

      expect(position.name).to eq("Normalpreis - Einstiegskurs")
      expect(position.grouping).to eq("Normalpreis - Einstiegskurs")
      expect(position.amount).to eq(20)
      expect(position.count).to eq(1)
      expect(position.article_number).to eq("49")
      expect(position.cost_center).to eq("kurs-1")
      expect(position.cost_unit).to eq("ski-1")
    end
  end

  context "#additional_user_fields" do
    it "sets additional user fields" do
      additional_user_fields = subject.additional_user_fields

      expect(additional_user_fields[:user_field8]).to eq(course.number)
      expect(additional_user_fields[:user_field9]).to eq(course.name)
      expect(additional_user_fields[:user_field10]).to eq("01.01.2024 - 31.01.2024, 01.03.2024 - 31.03.2024")
    end
  end
end
