# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Passes::Membership
  class Footer < Export::Pdf::Section
    EMERGENCY_SERVICES_DETAILS = "REGA 1414#{' ' * 20}SOS Europe 112".freeze

    TITLE_POSITION = [61.409, 155.561].freeze
    TITLE_ALIGN = :left
    TITLE_SIZE = 10
    TITLE_STYLE = :bold

    RECIPROCITY_IMAGE_POSITION = [496.714, 190.213].freeze
    RECIPROCITY_IMAGE_WIDTH = 39.885

    RIGHT_SIDE_LEFT_START = 309.425
    EMERGENCY_TEXT_POSITION = [RIGHT_SIDE_LEFT_START, 188.1799].freeze
    EMERGENCY_TEXT_SIZE = 8

    SAC_CAS_LINK_COLOR = 'ED1C24'
    SAC_CAS_LINK_POSITION = [489.973, 153.408].freeze
    SAC_CAS_LINK_SIZE = 7

    SPONSOR_QR_CODE_POSITION = [499, 88.126].freeze
    SPONSOR_QR_CODE_WIDTH = 55
    SPONSOR_CODE_POSITION = [499, 87].freeze
    SPONSOR_CODE_SIZE = 6

    TEXT_BOX_WIDTH = 170.017
    TEXT_BOX_HEIGHT = 28.063
    GRAY_BOXES_Y_POSITION = [175.307, 144.307].freeze
    TEXT_BOX_FILL_COLOR = 'EFEFEF'
    TEXT_BOX_COLOR = '231f20'

    DASHED_BOX_SCISSORS_IMAGE_POSITION = [14, 205.3].freeze
    DASHED_BOX_SCISSORS_IMAGE_WIDTH = 20
    DASH_PATTERN = [2, { style: 2 }].freeze

    MEMBERSHIP_CARD_HEIGHT = 162
    MEMBERSHIP_CARD_WIDTH = 256
    LEFT_MARGIN = 39
    BOTTOM_MARGIN = 37

    def render
      text_box title,
               at: TITLE_POSITION,
               align: TITLE_ALIGN,
               size: TITLE_SIZE,
               style: TITLE_STYLE

      draw_back
      draw_dashed_box
    end

    private

    def draw_back
      pdf.image(reciprocity_image_path, position: :left, at: RECIPROCITY_IMAGE_POSITION,
                                        width: RECIPROCITY_IMAGE_WIDTH)

      draw_sponsor_code

      text_box EMERGENCY_SERVICES_DETAILS,
               at: EMERGENCY_TEXT_POSITION,
               style: :bold,
               size: EMERGENCY_TEXT_SIZE

      write_in_boxes(RIGHT_SIDE_LEFT_START)

      sac_cas_link
    end

    def sac_cas_link
      fill_color(SAC_CAS_LINK_COLOR) do
        text_box 'www.sac-cas.ch',
                 at: SAC_CAS_LINK_POSITION,
                 size: SAC_CAS_LINK_SIZE
      end
    end

    def draw_sponsor_code
      pdf.image(sponsor_qr_code, position: :left, at: SPONSOR_QR_CODE_POSITION,
                                 width: SPONSOR_QR_CODE_WIDTH)
      text_box t('sac_partner'),
               at: SPONSOR_CODE_POSITION,
               align: :center,
               size: SPONSOR_CODE_SIZE,
               width: SPONSOR_QR_CODE_WIDTH
    end

    def write_in_boxes(right_side_left_start)
      fill_color(TEXT_BOX_FILL_COLOR) do
        GRAY_BOXES_Y_POSITION.each do |y_position|
          pdf.fill_rectangle [right_side_left_start, y_position], TEXT_BOX_WIDTH,
                             TEXT_BOX_HEIGHT
        end
      end

      fill_color(TEXT_BOX_COLOR) do
        [build_multilanguage_string('emergency_number'),
         build_multilanguage_string('emergency_contact')].each_with_index do |text, i|
          text_box text,
                   at: [right_side_left_start + 2, GRAY_BOXES_Y_POSITION[i] - 3],
                   align: :left,
                   size: 6
        end
      end
    end

    def build_multilanguage_string(key)
      [:de, :fr, :it].map do |lang|
        I18n.with_locale(lang) do
          t(key)
        end
      end.join(' / ')
    end

    def fill_color(color)
      original_fill_color = pdf.fill_color
      pdf.fill_color color
      yield
      pdf.fill_color = original_fill_color
    end

    def dashed_box_points
      left = LEFT_MARGIN
      right = MEMBERSHIP_CARD_WIDTH + left
      bottom = BOTTOM_MARGIN
      top = MEMBERSHIP_CARD_HEIGHT + bottom
      back_right = (MEMBERSHIP_CARD_WIDTH * 2) + left

      front_points = [
        [[left, top], [right, top]], [[left, top], [left, bottom]],
        [[right, top], [right, bottom]], [[left, bottom], [right, bottom]]
      ]

      back_points = [
        [[right, top], [back_right, top]],
        [[back_right, top], [back_right, bottom]],
        [[right, bottom], [back_right, bottom]]
      ]

      front_points + back_points
    end

    def draw_dashed_box
      pdf.image(scissors_image_path, position: :left, at: DASHED_BOX_SCISSORS_IMAGE_POSITION,
                                     width: DASHED_BOX_SCISSORS_IMAGE_WIDTH)
      pdf.dash(*DASH_PATTERN)

      # Draw the lines for both boxes
      dashed_box_points.each do |start_point, end_point|
        pdf.stroke_line(start_point, end_point)
      end

      pdf.undash
    end

    def sponsor_qr_code
      qr_code = RQRCode::QRCode.new(t('sponsor_url')).as_png(size: 70).to_s
      StringIO.new(qr_code)
    end

    def scissors_image_path
      image_path('membership_pass/scissors.png')
    end

    def reciprocity_image_path
      image_path('membership_pass/reciprocity_logo_membership_pass.png')
    end

    def image_path(name)
      Wagons.find_wagon(__FILE__).root.join('app', 'assets', 'images', name)
    end

    def t(key)
      I18n.t("passes.membership.#{key}")
    end

    def title
      I18n.t('passes.membership.title')
    end
  end
end
