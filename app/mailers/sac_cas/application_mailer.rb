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
    original_locale = I18n.locale
    locales = [I18n.locale] if locales.empty?
    headers[:to] = use_mailing_emails(recipients)

    contents = locales.map do |locale|
      content = localized_content_for(locale, content_key)
      content = localized_content_for(I18n.default_locale, content_key) if content.body.body.nil?
      headers[:subject] ||= content.subject_with_values(values) if locale == locales.first

      # TODO: make method public in core and remove .send
      content.send(:replace_placeholders, content.body.to_plain_text, values)
    end

    I18n.locale = original_locale
    mail(headers) { |format| format.html { render plain: join_contents(contents) } }
  end

  def localized_content_for(locale, content_key)
    I18n.locale = locale
    CustomContent.get(content_key)
  end

  def join_contents(contents)
    contents = contents.join("\n\n--------------------\n\n").gsub("\n", "<br>")
    "<div class=\"trix-content\">#{contents}</div>"
  end
end
