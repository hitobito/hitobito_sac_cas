# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Passes::Membership
  class Person < Export::Pdf::Section

    alias person model

    def render
      table_data = [[row_membership]]

      bounding_box([68, 711], width: 260, height: 500) do
        table(table_data, cell_style: { border_width: 0 })
      end

      image(verify_qr_code, at: [47, 147], width: 110, height: 110)
      bounding_box([176, 102], width: 200, height: 300) do
        membertext = [person_name, person_membership_number].flatten.join("\n\n")
        pdf.text_box(membertext, size: 9, style: :bold)
      end
    end

    private

    def row_membership
      attrs = [[person_address]]
      pdf.make_table(attrs) do
        cells.borders = []
        cells.size = 9
        columns([1, 3]).font_style = :bold
      end
    end

    def person_address
      ::Person::Address.new(person).for_letter
    end

    def person_name
      "#{person.person_name}"
    end

    def person_membership_number
      "#{t('member')}: #{person.membership_number}"
    end

    def verify_qr_code
      qr_code = People::Membership::VerificationQrCode.new(person).generate
      qr_code = qr_code.as_png(size: 70).to_s
      StringIO.new(qr_code)
    end

    def t(key)
      I18n.t("passes.membership.#{key}")
    end
  end
end
