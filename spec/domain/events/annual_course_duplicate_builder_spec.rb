# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SacCas::Events::AnnualCourseDuplicateBuilder do
  let(:builder) { described_class.new(blueprint_course, 2026) }
  let(:duplicate) { builder.build }

  let(:blueprint_application_opening_at) { Date.new(2025, 5, 26) } # Monday of calendar week 22 (attribute is a date in db)
  let(:blueprint_application_closing_at) { Date.new(2025, 6, 6) } # Friday of calendar week 23 (attribute is a date in db)
  let(:blueprint_start_at) { DateTime.new(2025, 7, 23, 10, 23) } # Wednesday of calendar week 30, 10:23
  let(:blueprint_finish_at) { DateTime.new(2025, 8, 1, 23, 59) } # Friday of calendar week 31, 23:59

  let(:blueprint_course) do
    course = Fabricate(:sac_open_course, number: "2025-1000",
      application_opening_at: blueprint_application_opening_at,
      application_closing_at: blueprint_application_closing_at)

    Event::Date.where(event: course).first.update!(start_at: blueprint_start_at, finish_at: blueprint_finish_at)

    [:de, :fr, :it].each do |locale|
      translation = Event::Translation.find_or_initialize_by(event_id: course.id, locale:)
      translation.attributes = translated_attributes.index_with { [Faker::Lorem.words.join, locale].join(" ") }
      translation.save!
    end

    3.times do
      question = Fabricate(:event_question, event: course)

      [:de, :fr, :it].each do |locale|
        translation = question.translations.find_or_initialize_by(locale:)
        translation.question = [Faker::Lorem.words.join, locale].join(" ")
        translation.save!
      end
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

  context "#build" do
    it "builds duplicate" do
      expect(duplicate.state).to eq("created")
      expect(duplicate.number).to eq("2026-1000")

      expect(duplicate.application_opening_at).to eq(Date.new(2026, 5, 25)) # Monday of calendar week 22
      expect(duplicate.application_closing_at).to eq(Date.new(2026, 6, 5)) # Friday of calendar week 23

      expect(duplicate.dates.first.start_at).to eq(DateTime.new(2026, 7, 22, 10, 23)) # Wednesday of calendar week 30, 10:23
      expect(duplicate.dates.first.finish_at).to eq(DateTime.new(2026, 7, 31, 23, 59)) # Friday of calendar week 31, 23:59

      expect(duplicate.translations.size).to eq(3)
      [:de, :fr, :it].each do |locale|
        blueprint_translations = blueprint_course.translations.find_by(locale:)
        duplicate_translations = duplicate.translations.find { _1.locale == locale }

        translated_attributes.each do |attr|
          expect(duplicate_translations.send(attr)).to eq(blueprint_translations.send(attr))
        end
      end

      expect(duplicate.questions.size).to eq(3)
      blueprint_course.questions.each do |blueprint_question|
        duplicate_question = duplicate.questions.find { _1.question == blueprint_question.question }

        [:de, :fr, :it].each do |locale|
          blueprint_translations = blueprint_question.translations.find_by(locale:)
          duplicate_translations = duplicate_question.translations.find { _1.locale == locale }

          expect(duplicate_translations.question).to eq(blueprint_translations.question)
        end
      end

      expect(duplicate).to be_valid
    end
  end

  context "#create" do
    it "creates course, dates, questions and translations" do
      duplicate = builder.create!

      expect(duplicate).to be_persisted
      expect(duplicate.translations.count).to eq(3)
      expect(duplicate.dates.count).to eq(1)

      expect(duplicate.questions.count).to eq(3)
      duplicate.questions.each do |question|
        expect(question.translations.count).to eq(3)
      end
    end
  end
end
