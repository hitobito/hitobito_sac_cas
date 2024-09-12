# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module MultiLanguageMailer
  extend ActiveSupport::Concern

  LANGUAGE_SEPARATOR = "<br><br>--------------------<br><br>"

  private

  def compose_multi_language(recipients, content_key, locales = [])
    return if recipients.blank?

    locales = [I18n.locale] if locales.empty?
    if locales.size == 1
      I18n.with_locale(locales.first) do
        values = values_for_placeholders(content_key)
        custom_content_mail(recipients, content_key, values)
      end
    else
      multi_language_custom_content_mail(recipients, content_key, locales)
    end
  end

  def multi_language_custom_content_mail(recipients, content_key, locales)
    headers[:to] = use_mailing_emails(recipients)

    content = CustomContent.get(content_key)
    subjects_and_bodies = locales.map { |locale| localized_subject_and_body(content, locale) }
    subject = subjects_and_bodies.map(&:first).compact_blank.uniq.join(" / ")
    body = subjects_and_bodies.map(&:last).compact_blank.join(LANGUAGE_SEPARATOR).html_safe

    I18n.with_locale(locales.first) do
      mail(subject: subject) { |format| format.html { render html: body, layout: true } }
    end
  end

  def localized_subject_and_body(content, locale)
    I18n.with_locale(locale) do
      values = values_for_placeholders(content.key)
      [content.subject_with_values(values), content.body_with_values(values)]
    end
  end
end
