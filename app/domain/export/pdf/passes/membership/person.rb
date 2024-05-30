# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Passes::Membership
  class Person < Export::Pdf::Section

    alias person model

    ADDRESS_BOUNDING_BOX_WIDTH = 180
    ADDRESS_BOUNDING_BOX_HEIGHT = 500
    ADDRESS_BOUNDING_BOX_POSITION = [65, 711].freeze
    ADDRESS_SIZE = 9

    QR_CODE_POSITION = [47, 147].freeze
    QR_CODE_WIDTH = 100
    QR_CODE_HEIGHT = 110

    MEMBER_TEXT_BOX_POSITION = [160, 102].freeze
    MEMBER_TEXT_BOX_WIDTH = 120
    MEMBER_TEXT_BOX_HEIGHT = 50
    MEMBER_TEXT_SIZE = 9
    MEMBER_TEXT_STYLE = :bold
    TEXT_OVERFLOW = :shrink_to_fit

    def render
      bounding_box(ADDRESS_BOUNDING_BOX_POSITION, width: ADDRESS_BOUNDING_BOX_WIDTH) do
        pdf.text_box(person_address, size: ADDRESS_SIZE,
                                     overflow: TEXT_OVERFLOW)
      end

      image(verify_qr_code, at: QR_CODE_POSITION, width: QR_CODE_WIDTH, height: QR_CODE_HEIGHT)
      bounding_box(MEMBER_TEXT_BOX_POSITION, width: MEMBER_TEXT_BOX_WIDTH,
                                             height: MEMBER_TEXT_BOX_HEIGHT) do
        membertext = [person_name, person_membership_number].flatten.join("\n\n")
        pdf.text_box(membertext, size: MEMBER_TEXT_SIZE, style: MEMBER_TEXT_STYLE,
                                 overflow: TEXT_OVERFLOW)
      end
    end

    private

    def person_address
      ::Person::Address.new(person).for_membership_pass
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
