class SacAddressPresenter
  def initialize(locale_data = I18n.t('global.sac'))
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
    when :leader_settlement
      leader_settlement_format
    end
  end

  private

  def self_registration_format
    <<~HTML.strip
      #{@data[:name]}
      #{@data[:address]}
      #{@data[:town]}
      Tel: <a href="tel:#{telephone_link(@data[:phone])}">#{@data[:phone]}</a>
      <a href="mailto:#{@data[:email_mv]}">#{@data[:email_mv]}</a>
    HTML
  end

  def key_data_sheet_format
    "#{@data[:name]}, #{@data[:address]}, #{@data[:postbox]}, CH-#{@data[:town]}, #{@data[:phone_self_registration]}, #{@data[:email]}"
  end

  def mail_format
    <<~HTML.strip
      #{@data[:name]}
      #{@data[:address]}
      #{@data[:town]}
      <a href="#{@data[:website]}">#{@data[:website]}</a>
    HTML
  end

  def leader_settlement_format
    "#{@data[:name]}\n#{@data[:zentralverband]}, #{@data[:address]}\n#{@data[:town]}\n\n\n"
  end

  def telephone_link(telephone)
    telephone.gsub(/\s+/, '')
  end
end
