# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::ApplicationMailer
  private

  def compose(recipients, content_key, locales = [])
    return if recipients.blank?

    values = values_for_placeholders(content_key)
    custom_content_mail(recipients, content_key, values, {}, locales)
  end

  def custom_content_mail(recipients, content_key, values, headers = {}, locales = [])
    content = CustomContent.get(content_key)
    locales = [I18n.locale] if locales.empty?
    headers[:to] = use_mailing_emails(recipients)

    contents = locales.map do |locale|
      I18n.with_locale(locale) do
        body, subject = content_subject_and_body(content, values, locale, locales)

        if body.blank?
          I18n.with_locale(I18n.default_locale) do
            body, subject = content_subject_and_body(content, values, locale, locales)
          end
        end

        headers[:subject] ||= subject
        content.replace_placeholders(body.to_plain_text, values)
      end
    end

    mail(headers) { |format| format.html { render plain: join_contents(contents) } }
  end

  def content_subject_and_body(content, values, locale, locales)
    [content.body, (content.subject_with_values(values) if locale == locales.first)]
  end

  def join_contents(contents)
    contents = contents.join("<br><br>--------------------<br><br>").gsub("\n", "<br>")
    "<div class=\"trix-content\">#{contents}</div>"
  end
end
