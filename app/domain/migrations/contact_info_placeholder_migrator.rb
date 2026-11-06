# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Migrations
  # Replaces the contact name, phone and email placeholders in custom content
  # subjects and bodies of all locales with {contact-info} and resets the german
  # section templates using them.
  class ContactInfoPlaceholderMigrator
    RESET_KEYS = [
      Event::TourApprovalMailer::REQUIRED,
      Event::TourApprovalMailer::REJECTED,
      Event::TourApprovalMailer::GRANTED,
      Event::TourApprovalMailer::SELF_APPROVED,
      Event::TourMailer::PUBLICATION,
      Event::TourMailer::PUBLICATION_SUBITO,
      Event::TourMailer::BACK_TO_DRAFT,
      Event::TourMailer::BACK_TO_APPROVED,
      Event::TourMailer::BACK_TO_PUBLISHED,
      Event::TourMailer::BACK_TO_READY,
      Event::TourParticipationMailer::CLOSING,
      Event::TourParticipationMailer::CANCELED_MINIMUM_PARTICIPANTS,
      Event::TourParticipationMailer::CANCELED_NO_LEADER,
      Event::TourParticipationMailer::CANCELED_WEATHER,
      Event::TourParticipationMailer::ASSIGNED,
      Event::TourParticipationMailer::UNCONFIRMED,
      Event::TourParticipationMailer::SUMMONED_PARTICIPATION,
      Event::TourParticipationMailer::REJECT_PARTICIPATION,
      Event::TourParticipationMailer::CANCELED_PARTICIPATION
    ].freeze

    CONTACT_INFO = "{contact-info}"
    LEGACY_PLACEHOLDER = /\{contact-(?:first-name|last-name|phone|email)\}/
    LEGACY_PLACEHOLDER_WITH_SEPARATOR = /[\s,]*#{LEGACY_PLACEHOLDER}/
    LEGACY_PLACEHOLDER_SQL = '\{contact-(first-name|last-name|phone|email)\}'
    FULL_NAME = /\{contact-first-name\}\s*\{contact-last-name\}/
    CONTACT_DETAILS_PARENTHESES =
      /\s*\(\s*\{contact-(?:id|phone|email)\}(?:\s*,\s*\{contact-(?:id|phone|email)\})*\s*\)/

    def rewrite_placeholders
      rewrite_subjects + rewrite_bodies
    end

    def reset_section_templates
      templates = CustomContent.section_specific_templates
      contents = CustomContent.unscoped.where(
        key: RESET_KEYS,
        context_type: Group.sti_name,
        context_id: Group.where(type: SacCas::MEMBERSHIP_OPERATIONS_GROUP_TYPES).select(:id)
      )

      I18n.with_locale(:de) do
        rewrite_each(contents) { |content| reset(content, templates.fetch(content.key)) }
      end
    end

    private

    def rewrite_subjects
      translations = CustomContent::Translation.where("subject ~ ?", LEGACY_PLACEHOLDER_SQL)

      rewrite_each(translations) do |translation|
        translation.update_columns(subject: rewrite(translation.subject))
      end
    end

    def rewrite_bodies
      rich_texts = ActionText::RichText
        .where(record_type: CustomContent::Translation.polymorphic_name, name: "body")
        .where("body ~ ?", LEGACY_PLACEHOLDER_SQL)

      rewrite_each(rich_texts) do |rich_text|
        rich_text.update!(body: rewrite(rich_text.body.to_html))
      end
    end

    def reset(content, template)
      content.update!(
        subject: template["subject"],
        body: template["body"].split("\n").join("\n<br>\n")
      )
    end

    def rewrite_each(scope, &)
      count = scope.count
      scope.find_each(&)
      count
    end

    def rewrite(text)
      text = remove_contact_details_parentheses(text)
      text = replace_full_name(text)
      replace_remaining(text)
    end

    def remove_contact_details_parentheses(text)
      text.gsub(CONTACT_DETAILS_PARENTHESES) do |match|
        (match.strip == "({contact-id})") ? match : ""
      end
    end

    def replace_full_name(text)
      text.gsub(FULL_NAME, CONTACT_INFO)
    end

    def replace_remaining(text)
      text = text.sub(LEGACY_PLACEHOLDER, CONTACT_INFO) unless text.include?(CONTACT_INFO)
      text.gsub(LEGACY_PLACEHOLDER_WITH_SEPARATOR, "")
    end
  end
end
