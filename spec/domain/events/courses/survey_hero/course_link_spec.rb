# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Events::Courses::SurveyHero::CourseLink do
  let(:course) { events(:top_course) }
  let(:client) { instance_double(Events::Courses::SurveyHero::Client) }

  subject(:link) { described_class.new(course, client:).create }

  before do
    course.update!(
      survey_hero_survey_key: "5367281",
      survey_hero_collector_key: "8294016",
      name: "Skikurs & Lawinen"
    )
    allow(client).to receive(:copy_collector).and_return("https://www.umfrageonline.com/c/abc")
  end

  def query
    Rack::Utils.parse_query(URI.parse(link).query)
  end

  it "copies collector of course keys named after course" do
    link

    expect(client).to have_received(:copy_collector)
      .with("5367281", "8294016", name: "SAC Kursumfrage: Skikurs & Lawinen (10)")
  end

  it "appends course params to collector link" do
    expect(link).to start_with "https://www.umfrageonline.com/c/abc?"
    expect(query).to eq(
      "course-id" => "10",
      "coursename" => "Skikurs & Lawinen",
      "event-start" => "01.03.2023",
      "event-finish" => "10.04.2023"
    )
  end

  it "uses start of last date as event-finish when it has no finish" do
    event_dates(:top_course_second).update!(finish_at: nil)
    course.reload

    expect(query["event-finish"]).to eq "03.04.2023"
  end

  it "uses course name in course language" do
    I18n.with_locale(:fr) { course.update!(name: "Cours de ski") }
    course.update!(language: "fr")

    expect(query["coursename"]).to eq "Cours de ski"
  end

  it "uses german course name for bilingual course" do
    I18n.with_locale(:fr) { course.update!(name: "Cours de ski") }
    course.update!(language: "de_fr")

    expect(query["coursename"]).to eq "Skikurs & Lawinen"
  end
end
