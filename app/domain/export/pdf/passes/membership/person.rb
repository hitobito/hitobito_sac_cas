# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Passes::Membership
  class Person < Export::Pdf::Section

    alias person model

    def render
      pdf.move_down(20)
      table_data = [[row_membership], [row_address_qr]]
      table(table_data, cell_style: { border_width: 0 })
    end

    private

    def row_address_qr
      data = [[person_address, { image: verify_qr_code }]]
      pdf.make_table(data) do
        cells.borders = []
        cells.size = 24
        cells.font_style = :bold
        cells.valign = :center
        columns(1).width = 280
      end
    end

    def row_membership
      attrs = [[t('membership_years'), person.membership_years]]
      pdf.make_table(attrs) do
        cells.borders = []
        cells.size = 16
        columns([1, 3]).font_style = :bold
      end
    end

    def person_address
      ::Person::Address.new(person).for_letter
    end

    def verify_qr_code
      qr_code = RQRCode::QRCode.new(verify_url).as_png(size: 220).to_s
      StringIO.new(qr_code)
    end

    def verify_url
      host = ENV.fetch('RAILS_HOST_NAME', 'localhost:3000')
      # Rails
      #   .application
      #   .routes
      #   .url_helpers
      #   .verify_membership_url(host: host, verify_token: membership_verify_token)
    end

    def membership_verify_token
      person.membership_verify_token.presence || person.init_membership_verify_token!
    end

    def t(key)
      I18n.t("passes.membership.#{key}")
    end

  end
end
