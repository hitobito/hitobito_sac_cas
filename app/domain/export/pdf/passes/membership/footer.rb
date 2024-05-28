# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Passes::Membership
  class Footer < Export::Pdf::Section

    def render
      text_box title,
               at: [61.409, 155.561],
               align: :left,
               size: 10,
               style: :bold

      draw_back
      draw_dashed_box
    end

    private

    def draw_back
      pdf.image(reciprocity_image_path, position: :left, at: [496.714, 190.213],
                                        width: 39.885)

      draw_sponsor_code

      right_side_left_start = 309.425

      text_box 'REGA 1414                    SOS Europe 112',
               at: [right_side_left_start,
                    188.1799],
               style: :bold,
               size: 8

      write_in_boxes(right_side_left_start)

      sac_cas_link
    end

    def sac_cas_link
      fill_color('ED1C24') do
        text_box 'www.sac-cas.ch',
                 at: [489.973,
                      153.408],
                 size: 7
      end
    end

    def draw_sponsor_code
      sponsor_qr_code_width = 55
      pdf.image(sponsor_qr_code, position: :left, at: [499, 88.126],
                                 width: sponsor_qr_code_width)
      text_box t('sac_partner'),
               at: [499,
                    87],
               align: :center,
               size: 6,
               width: sponsor_qr_code_width
    end

    def write_in_boxes(right_side_left_start)
      text_box_width = 170.017
      text_box_height = 28.063
      gray_boxes_y_position = [175.307, 144.307]

      fill_color('EFEFEF') do
        gray_boxes_y_position.each do |y_position|
          pdf.fill_rectangle [right_side_left_start, y_position], text_box_width,
                             text_box_height
        end
      end

      fill_color('231f20') do
        ["Notfallnummer / N° d'urgence / No. di emergenza",
         "Notfallkontakt / Contact d'urgence / Contatto di emergenza"].each_with_index do |text, i|
          text_box text,
                   at: [right_side_left_start + 2, gray_boxes_y_position[i] - 3],
                   align: :left,
                   size: 6
        end
      end
    end

    def fill_color(color)
      original_fill_color = pdf.fill_color
      pdf.fill_color color
      yield
      pdf.fill_color = original_fill_color
    end

    def dashed_box_points
      membership_card_height = 162
      membership_card_width = 256

      left = 39
      right = membership_card_width + left
      bottom = 37
      top = membership_card_height + bottom
      back_right = (membership_card_width * 2) + left

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
      pdf.image(scissors_image_path, position: :left, at: [14, 205.3],
                                     width: 20)
      pdf.dash(2, space: 2)

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
