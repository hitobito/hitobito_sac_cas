# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Migrations
  # Moves the emergency contact answers of courses numbered with NUMBER_PREFIX
  # into the dedicated person columns and removes the legacy global questions
  # and their templates afterwards.
  class EmergencyContactAnswersMigrator
    NUMBER_PREFIX = "2027"

    LEGACY_QUESTIONS = {
      "Notfallkontakt 1 - Name und Telefonnummer" => :emergency_contact_1_name,
      "Notfallkontakt 2 - Name und Telefonnummer" => :emergency_contact_2_name
    }.freeze

    def copy_answers
      legacy_questions.each do |question|
        copy_answers_of(question, target_attribute(question))
      end
    end

    def remove_legacy_questions
      question_ids = legacy_questions.pluck(:id)

      destroy_questions(question_ids)
    end

    private

    def copy_answers_of(question, attr)
      answers_for(question).each do |answer|
        person = answer.participation.participant
        next if person[attr].present?

        person.update_columns(attr => answer.answer.to_s)
      end
    end

    def answers_for(question)
      Event::Answer.joins(participation: :event)
        .where(question: question)
        .where(event_participations: {participant_type: Person.sti_name})
        .where("events.number LIKE ?", "#{NUMBER_PREFIX}%")
    end

    def target_attribute(question)
      LEGACY_QUESTIONS.fetch(de_text(question))
    end

    def de_text(question)
      question.translations.where(locale: "de").pick(:question)
    end

    def legacy_questions
      @legacy_questions ||= questions_scope.to_a
    end

    def questions_scope
      Event::Question.joins(:translations).left_joins(:event)
        .where(event_question_translations: {locale: "de"})
        .where(event_question_translations: {question: LEGACY_QUESTIONS.keys})
        .order(Arel.sql("events.number DESC"))
    end

    def destroy_questions(ids)
      return if ids.empty?

      Event::QuestionTemplate.where(question_id: ids).delete_all
      Event::Answer.where(question_id: ids).delete_all
      Event::QuestionVisibility.where(question_id: ids).delete_all
      Event::Question::Translation.where(event_question_id: ids).delete_all
      Event::Question.where(id: ids).delete_all
    end
  end
end
