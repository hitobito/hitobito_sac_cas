# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Nav21EventParticipationsImporter do
  let(:sac_imports_src) { file_fixture("sac_imports_src").expand_path }
  let(:output) { double(puts: nil, print: nil) }
  let(:report) { described_class.new(output: output) }
  let(:report_file) { Rails.root.join("log", "sac_imports", "nav21-event-participations_2024-01-23-1142.csv") }
  let(:report_headers) {
    %w[event_number person_id status errors]
  }
  let(:csv_report) { CSV.read(report_file, col_sep: ";") }

  before do
    File.delete(report_file) if File.exist?(report_file)
    stub_const("SacImports::CsvSource::SOURCE_DIR", sac_imports_src)
  end

  it "creates report for entries in source file" do
    Event::Participation.destroy_all
    events(:top_course).update!(training_days: 3)
    events(:top_course).init_questions(disclosure: :optional)
    events(:assignment_closed).update!(training_days: 5)
    events(:assignment_closed).init_questions(disclosure: :optional)
    Group.root.update!(course_admin_email: "kurse@example.com")

    expected_output = []
    expected_output << "102 - 699999: ❌ Person muss ausgefüllt werden, Effektive Tage darf nicht länger als geplante Kursdauer sein."
    expected_output << "101 - 600001: ❌ Status ist kein gültiger Wert"

    expect(output).to receive(:puts).with("The file contains 13 rows.")
    expected_output.flatten.each do |output_line|
      expect(output).to receive(:puts).with(output_line)
    end
    expect(output).to receive(:puts).with("\n\n\nReport generated in 0.0 minutes.")
    expect(output).to receive(:puts).with("Thank you for flying with SAC Imports.")
    expect(output).to receive(:puts).with("Report written to #{report_file}")

    travel_to DateTime.new(2024, 1, 23, 10, 42)

    questions = Event::Question.global.count
    expect(questions).to be > 1

    expect { report.create }
      .to change { Event::Participation.count }.by(10).and \
        change { Event::Role.count }.by(10).and \
          change { Event::Application.count }.by(8).and \
            change { Event::Answer.count }.by(questions * 10).and \
              change { Delayed::Job.count }.by(0) # make sure no emails are enqueued

    course10 = events(:top_course).reload
    expect(course10.participations.count).to eq(6)
    p1 = course10.participations.find { |p| p.person_id == 600000 }
    expect(p1.attributes.symbolize_keys).to include(
      additional_information: nil,
      active: true,
      qualified: false,
      canceled_at: nil,
      state: "assigned",
      cancel_statement: nil,
      subsidy: false,
      actual_days: 3,
      price: nil,
      price_category: nil
    )
    expect(p1.application).to be(nil)
    expect(p1.roles.first).to be_a(Event::Course::Role::Leader)
    expect(p1.roles.first.label).to be(nil)
    expect(p1.roles.first.self_employed).to be(true)
    expect(p1.answers.count).to eq(questions)

    p2 = course10.participations.find { |p| p.person_id == 600001 }
    expect(p2.attributes.symbolize_keys).to include(
      additional_information: nil,
      active: true,
      qualified: false,
      canceled_at: nil,
      state: "assigned",
      cancel_statement: nil,
      subsidy: false,
      actual_days: 3,
      price: nil,
      price_category: nil
    )
    expect(p2.application).to be(nil)
    expect(p2.roles.first).to be_a(Event::Course::Role::AssistantLeader)
    expect(p2.roles.first.label).to eq("Hilfssheriff")
    expect(p2.roles.first.self_employed).to be(false)

    p3 = course10.participations.find { |p| p.person_id == 600002 }
    expect(p3.attributes.symbolize_keys).to include(
      additional_information: nil,
      active: false,
      qualified: false,
      canceled_at: nil,
      state: "unconfirmed",
      cancel_statement: nil,
      subsidy: false,
      actual_days: nil,
      price: 180,
      price_category: "price_member"
    )
    expect(p3.application.priority_1).to eq(course10)
    expect(p3.application.approved).to be(false)
    expect(p3.application.rejected).to be(false)
    expect(p3.roles.first).to be_a(Event::Course::Role::Participant)
    expect(p3.roles.first.self_employed).to be(false)
    expect(p3.answers.count).to eq(questions)

    p4 = course10.participations.find { |p| p.person_id == 600003 }
    expect(p4.attributes.symbolize_keys).to include(
      additional_information: "Gerne Vegi",
      active: false,
      state: "applied"
    )
    expect(p4.application.approved).to be(false)
    expect(p4.application.rejected).to be(false)

    p5 = course10.participations.find { |p| p.person_id == 600004 }
    expect(p5.attributes.symbolize_keys).to include(
      active: false,
      state: "rejected"
    )
    expect(p5.application.approved).to be(false)
    expect(p5.application.rejected).to be(true)

    p6 = course10.participations.find { |p| p.person_id == 600005 }
    expect(p6.attributes.symbolize_keys).to include(
      active: true,
      state: "assigned",
      price: 200,
      price_category: "price_regular"
    )
    expect(p6.application.approved).to be(true)
    expect(p6.application.rejected).to be(false)

    expect(course10.participant_count).to eq(1)
    expect(course10.teamer_count).to eq(2)
    expect(course10.applicant_count).to eq(3)
    expect(course10.unconfirmed_count).to eq(1)

    course102 = events(:assignment_closed).reload
    expect(course102.participations.count).to eq(4)

    p1 = course102.participations.find { |p| p.person_id == 600002 }
    expect(p1.attributes.symbolize_keys).to include(
      active: true,
      state: "summoned"
    )
    expect(p1.application.approved).to be(true)
    expect(p1.application.rejected).to be(false)
    expect(p1.answers.count).to eq(questions)

    p2 = course102.participations.find { |p| p.person_id == 600003 }
    expect(p2.attributes.symbolize_keys).to include(
      active: true,
      state: "attended",
      subsidy: true,
      qualified: true,
      actual_days: 3,
      price: 80,
      price_category: "price_subsidized"
    )
    expect(p2.application.approved).to be(true)
    expect(p2.application.rejected).to be(false)

    p3 = course102.participations.find { |p| p.person_id == 600004 }
    expect(p3.attributes.symbolize_keys).to include(
      active: false,
      state: "absent"
    )
    expect(p3.application.approved).to be(true)
    expect(p3.application.rejected).to be(false)

    p4 = course102.participations.find { |p| p.person_id == 600005 }
    expect(p4.attributes.symbolize_keys).to include(
      active: false,
      state: "canceled",
      canceled_at: Date.new(2024, 8, 23),
      cancel_statement: "Keine Lust"
    )
    expect(p4.application.approved).to be(true)
    expect(p4.application.rejected).to be(false)

    expect(course102.participant_count).to eq(2)
    expect(course102.teamer_count).to eq(0)
    expect(course102.applicant_count).to eq(3)
    expect(course102.unconfirmed_count).to eq(0)

    expect(File.exist?(report_file)).to be_truthy

    expect(csv_report.size).to eq(5)
    expect(csv_report.first).to eq(report_headers)
    expect(csv_report[1..]).to eq(
      [["102", "699999", "error", "Person muss ausgefüllt werden, Effektive Tage darf nicht länger als geplante Kursdauer sein."],
        ["99999", "600000", "warning", "Event with number '99999' couldn't be found"],
        ["101", "600001", "warning", "Price category 'price_special' is not known, Role type 'other' is not known"],
        ["101", "600001", "error", "Status ist kein gültiger Wert"]]
    )

    File.delete(report_file)
    expect(File.exist?(report_file)).to be(false)
  end
end
