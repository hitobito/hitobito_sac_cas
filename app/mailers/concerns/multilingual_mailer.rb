# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module MultilingualMailer
  extend ActiveSupport::Concern

  LANGUAGE_SEPARATOR = "<br><br>--------------------<br><br>"

  private

  def compose_multilingual(recipients, content_key, locales = [])
    return if recipients.blank?

    content = CustomContent.get(content_key)
    locales = [I18n.locale] if locales.empty?
    subject, body = localized_subject_and_body(content, locales)
    headers[:to] = use_mailing_emails(recipients)

    # use default locale if no translation is available to avoid sending empty mail
    if body.blank?
      subject, body = localized_subject_and_body(content, [I18n.default_locale])
    end

    I18n.with_locale(locales.first) do
      html = ActionController::Base.helpers.sanitize(body, tags: %w[a br div])
      mail(subject:) { |format| format.html { render html:, layout: true } }
    end
  end

  def localized_subject_and_body(content, locales)
    subjects_and_bodies = locales.map do |locale|
      I18n.with_locale(locale) do
        values = values_for_placeholders(content.key)
        [content.subject_with_values(values), content.body_with_values(values)]
      end
    end

    [subjects_and_bodies.map(&:first).compact_blank.uniq.join(" / "),
      subjects_and_bodies.map(&:last).compact_blank.join(LANGUAGE_SEPARATOR)]
  end
end
