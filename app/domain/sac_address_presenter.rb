class SacAddressPresenter
  def initialize(locale_data = I18n.t("global.sac"))
    @data = locale_data
  end

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
      #{@data[:name]}
      #{@data[:address]}
      #{@data[:zip_code_and_town]}
      Tel: <a href="tel:#{telephone_link(@data[:phone])}">#{@data[:phone]}</a>
      <a href="mailto:#{@data[:email_mv]}">#{@data[:email_mv]}</a>
    HTML
  end

  def key_data_sheet_format
    "#{@data[:name]}, #{@data[:address]}, #{@data[:postbox]}, " \
      "CH-#{@data[:zip_code_and_town]}, #{@data[:phone_self_registration]}, #{@data[:email]}"
  end

  def mail_format
    <<~HTML.strip
      #{@data[:name]}
      #{@data[:address]}
      #{@data[:zip_code_and_town]}
      <a href="#{@data[:website]}">#{@data[:website]}</a>
    HTML
  end

  def leader_settlement_invoice_attributes
    {
      recipient_name: @data[:name],
      recipient_street: "#{@data[:zentralverband]}, #{@data[:street]}",
      recipient_housenumber: @data[:housenumber],
      recipient_zip_code: @data[:zip_code],
      recipient_town: @data[:town],
      recipient_country: @data[:country]
    }
  end

  def telephone_link(telephone)
    telephone.gsub(/\s+/, "")
  end
end
