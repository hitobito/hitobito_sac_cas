require "spec_helper"

describe SacCas::Events::AnnualCourseDuplicator do
  subject { SacCas::Events::AnnualCourseDuplicator.new(blueprint_course, "2025", "2026").build }

  let(:duplicate) { subject }
  let(:blueprint_application_opening_at) { Date.new(2025, 5, 26) } # Monday of calendar week 22
  let(:blueprint_application_closing_at) { Date.new(2025, 6, 6) } # Friday of calendar week 23
  let(:blueprint_start_at) { Date.new(2025, 7, 23) } # Wednesday of calendar week 30
  let(:blueprint_finish_at) { Date.new(2025, 8, 1) } # Friday of calendar week 31

  let(:blueprint_course) do
    course = Fabricate(:sac_open_course, number: "2025-1000",
      application_opening_at: blueprint_application_opening_at,
      application_closing_at: blueprint_application_closing_at)

    Event::Date.where(event: course).first.update!(start_at: blueprint_start_at, finish_at: blueprint_finish_at)

    [:de, :fr, :it].each do |locale|
      translation = Event::Translation.find_or_initialize_by(event_id: course.id, locale:)
      translation.attributes = translated_attributes.index_with { Faker::Lorem.words.join + " #{locale}" }
      translation.save!
    end

    course.reload
  end

  let(:translated_attributes) {
    [
      "name",
      "description",
      "application_conditions",
      "signature_confirmation_text",
      "brief_description",
      "specialities",
      "similar_tours",
      "program"
    ]
  }

  it "creates duplicate" do
    expect(duplicate.state).to eq("created")
    expect(duplicate.number).to eq("2026-1000")

    expect(duplicate.application_opening_at).to eq(Date.new(2026, 5, 25)) # Monday of calendar week 22
    expect(duplicate.application_closing_at).to eq(Date.new(2026, 6, 5)) # Friday of calendar week 23

    expect(duplicate.dates.first.start_at.to_date).to eq(Date.new(2026, 7, 22)) # Wednesday of calendar week 30
    expect(duplicate.dates.first.finish_at.to_date).to eq(Date.new(2026, 7, 31)) # Friday of calendar week 31

    expect(duplicate.translations.size).to eq(3)
    [:de, :fr, :it].each do |locale|
      translated_attributes.each do |attr|
        expect(duplicate.translations.find { _1.locale == locale }.send(attr)).to eq(blueprint_course.translations.find_by(locale:).send(attr))
      end
    end
  end
end
