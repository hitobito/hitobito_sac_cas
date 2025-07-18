# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# Sends emails with custom content in potentially multiple languages.
# This is primarly used for multilingual course emails.
# To send an email in a single specific language, use `I18n.with_locale { compose(...) }`
module MultilingualMailer
  extend ActiveSupport::Concern

  LANGUAGE_SEPARATOR = ("<br/>".html_safe * 2 + "--------------------" + "<br/>".html_safe * 2).freeze

  private

  def compose_multilingual(recipients, content_key, locales = [])
    return if recipients.blank?

    locales = [I18n.locale] if locales.empty?
    if locales.size == 1
      I18n.with_locale(locales.first) { compose(recipients, content_key) }
    else
      do_compose_multilingual(recipients, content_key, locales)
    end
  end

  def do_compose_multilingual(recipients, content_key, locales)
    view_context  # must be set explicitly for draper see (hitobito/hitobito#6f310725c2)

    content = CustomContent.get(content_key)
    subject, body = localized_subject_and_body(content, locales)
    headers[:to] = use_mailing_emails(recipients)

    I18n.with_locale(locales.first) do
      mail(subject:) do |f|
        f.html { render html: body, layout: true }
      end
    end
  end

  def localized_subject_and_body(content, locales)
    subjects_and_bodies = locales.map do |locale|
      I18n.with_locale(locale) do
        values = values_for_placeholders(content.key)
        [content.subject_with_values(values), content.body_with_values(values)]
      end
    end

    subject_encoded = subjects_and_bodies.map(&:first).compact_blank.uniq.join(" / ")
    subject = CGI.unescapeHTML(subject_encoded)
    body = join_lines(subjects_and_bodies.map(&:last).compact_blank, LANGUAGE_SEPARATOR)

    [subject, body]
  end
end
