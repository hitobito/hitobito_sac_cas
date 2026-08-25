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

    def initialize(template_ids: [])
      @template_ids = Array(template_ids)
    end

    def list_templates
      legacy_templates.map do |template|
        [template.id, template.group_id, template.default, template.event_type, de_text(template)]
      end
    end

    def copy_answers
      updated = 0
      Event::Question.transaction do
        legacy_templates.each do |template|
          updated += copy_answers_of(derived_question_ids(template), target_attribute(template))
        end
      end
      updated
    end

    def remove_legacy_questions
      Event::Question.transaction do
        template_ids = legacy_templates.map(&:id)
        derived_ids = Event::Question.where(template_id: template_ids).pluck(:id)

        destroy_questions(derived_ids)
        Event::QuestionTemplate.where(id: template_ids).delete_all
        destroy_questions(legacy_templates.map(&:question_id))
      end
    end

    private

    def copy_answers_of(question_ids, attr)
      updated = 0
      answers_for(question_ids).each do |answer|
        person = answer.participation.participant
        next if person[attr].present?

        person.update_columns(attr => answer.answer.to_s)
        updated += 1
      end
      updated
    end

    def answers_for(question_ids)
      Event::Answer.joins(participation: :event)
        .where(question_id: question_ids)
        .where(event_participations: {participant_type: Person.sti_name})
        .where("events.number LIKE ?", "#{NUMBER_PREFIX}%")
        .order(Arel.sql("events.number DESC"))
    end

    def derived_question_ids(template)
      Event::Question.where(template_id: template.id).select(:id)
    end

    def target_attribute(template)
      LEGACY_QUESTIONS.fetch(de_text(template))
    end

    def de_text(template)
      template.question.translations.where(locale: "de").pick(:question)
    end

    def legacy_templates
      @legacy_templates ||= template_scope.to_a
    end

    def template_scope
      scope = Event::QuestionTemplate.joins(question: :translations)
        .where(event_question_translations: {locale: "de"})
      if @template_ids.present?
        scope.where(id: @template_ids)
      else
        scope.where(event_question_translations: {question: LEGACY_QUESTIONS.keys})
      end
    end

    def destroy_questions(ids)
      return if ids.empty?

      Event::Answer.where(question_id: ids).delete_all
      Event::QuestionVisibility.where(question_id: ids).delete_all
      Event::Question::Translation.where(event_question_id: ids).delete_all
      Event::Question.where(id: ids).delete_all
    end
  end
end
