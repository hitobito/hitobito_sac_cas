# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Migrations::EmergencyContactAnswersMigrator do
  let(:migrator) { described_class.new }
  let(:person) { Fabricate(:person) }

  def create_course_with_answer(number:, answer_text:, contact:, participant: person)
    template = event_question_templates(:"notfallkontakt_#{contact}_template")
    course = Fabricate(:sac_course, number: number)

    question = template.derive_question.tap { |q| q.event = course }
    question.save!

    participation = Fabricate(:event_participation, event: course, participant: participant)
    answer = Event::Answer.find_or_initialize_by(participation: participation, question: question)
    answer.answer = answer_text
    answer.save!

    question
  end

  describe "#copy_answers" do
    it "copies the whole answer text into the name column of contact 1" do
      create_course_with_answer(number: "2027-001", answer_text: "Tina Muster / 079 111 22 33", contact: 1)

      expect { migrator.copy_answers }.to change { person.reload.emergency_contact_1_name }
        .from(nil).to("Tina Muster / 079 111 22 33")
      expect(person.emergency_contact_1_phone).to be_nil
    end

    it "copies the whole answer text into the name column of contact 2" do
      create_course_with_answer(number: "2027-001", answer_text: "Xanthippe Muster / 079 444 55 66",
        contact: 2)

      expect { migrator.copy_answers }.to change { person.reload.emergency_contact_2_name }
        .from(nil).to("Xanthippe Muster / 079 444 55 66")
      expect(person.emergency_contact_2_phone).to be_nil
    end

    it "does not copy answers of courses with a different number prefix" do
      create_course_with_answer(number: "2026-001", answer_text: "Tina Muster", contact: 1)

      expect { migrator.copy_answers }.not_to change { person.reload.emergency_contact_1_name }
    end

    it "does not overwrite existing emergency contacts" do
      person.update!(emergency_contact_1_name: "Existing Kontakt")
      create_course_with_answer(number: "2027-001", answer_text: "Tina Muster", contact: 1)

      expect { migrator.copy_answers }.not_to change { person.reload.emergency_contact_1_name }
    end

    it "uses the answer of the course with the highest number if a person participates in several" do
      create_course_with_answer(number: "2027-001", answer_text: "Früher Kurs", contact: 1)
      create_course_with_answer(number: "2027-002", answer_text: "Späterer Kurs", contact: 1)

      migrator.copy_answers

      expect(person.reload.emergency_contact_1_name).to eq "Späterer Kurs"
    end
  end

  describe "#remove_legacy_questions" do
    it "removes templates, global questions and derived questions with answers" do
      derived_question =
        create_course_with_answer(number: "2027-001", answer_text: "Tina Muster", contact: 1)
      template = event_question_templates(:notfallkontakt_1_template)
      global_question = event_questions(:notfallkontakt_1)

      expect { migrator.remove_legacy_questions }
        .to change { Event::Answer.where(question_id: derived_question.id).count }.by(-1)
        .and change { Event::Question.exists?(derived_question.id) }.from(true).to(false)
        .and change { Event::QuestionTemplate.exists?(template.id) }.from(true).to(false)
        .and change { Event::Question.exists?(global_question.id) }.from(true).to(false)
    end

    it "keeps unrelated questions, templates and their answers untouched" do
      course = Fabricate(:sac_course)
      participation = Fabricate(:event_participation, event: course, participant: person)
      unrelated_question = Event::Question.create!(question: "Andere Frage", event: course)
      unrelated_answer = Event::Answer.find_or_initialize_by(participation: participation,
        question: unrelated_question)
      unrelated_answer.answer = "Unverändert"
      unrelated_answer.save!
      unrelated_template = Event::QuestionTemplate.create!(group: Group.root,
        question: Event::Question.create!(question: "Globale andere Frage"))

      migrator.remove_legacy_questions

      expect(unrelated_answer.reload.answer).to eq "Unverändert"
      expect(Event::Question.exists?(unrelated_question.id)).to be true
      expect(Event::QuestionTemplate.exists?(unrelated_template.id)).to be true
    end
  end
end
