#  Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacAddressPresenter
  def format(format_type)
    case format_type
    when :self_registration
      self_registration_format
    when :key_data_sheet
      key_data_sheet_format
    when :mail
      mail_format
    when :leader_settlement_invoice_attributes
      leader_settlement_invoice_attributes
    end
  end

  private

  def self_registration_format
    <<~HTML.strip
      #{data[:name]}
      #{data[:address]}
      #{data[:zip_code_and_town]}
      Tel: <a href="tel:#{telephone_link(data[:phone])}">#{data[:phone]}</a>
      <a href="#{data[:contact_form_url]}" target="_blank" rel="noopener">#{data[:contact_form_label]}</a>
    HTML
  end

  def key_data_sheet_format
    "#{data[:name]}, #{data[:address]}, #{data[:postbox]}, " \
      "CH-#{data[:zip_code_and_town]}, #{data[:phone_self_registration]}, #{data[:email]}"
  end

  def mail_format
    <<~HTML.strip
      #{data[:name]}
      #{data[:address]}
      #{data[:zip_code_and_town]}
      <a href="#{data[:website]}">#{data[:website]}</a>
    HTML
  end

  def leader_settlement_invoice_attributes
    {
      recipient_last_name: data[:name],
      recipient_street: "#{data[:zentralverband]}, #{data[:street]}",
      recipient_housenumber: data[:housenumber],
      recipient_zip_code: data[:zip_code],
      recipient_town: data[:town],
      recipient_country: data[:country]
    }
  end

  def data
    @data ||= I18n.t("global.sac")
  end

  def telephone_link(telephone)
    telephone.gsub(/\s+/, "")
  end
end
