# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::AttendanceConfirmation::Sections::Header < Export::Pdf::Section
  LOGO_WIDTH = 183
  LOGO_HEIGHT = 76.5
  LOGO_TOP = 33
  LOGO_OVERHANG_RIGHT = 22.7
  LINK_TOP = 53.9
  LINK_FONT_SIZE = 8.5

  def render
    image(logo_path, width: LOGO_WIDTH, height: LOGO_HEIGHT,
      at: [bounds.right + LOGO_OVERHANG_RIGHT - LOGO_WIDTH, from_page_top(LOGO_TOP)])
    offset_cursor_from_top(LINK_TOP)
    text("<link href=\"#{t(:url)}\"><color rgb=\"E3000F\">#{t(:link)}</color></link>",
      inline_format: true, style: :bold, size: LINK_FONT_SIZE)
  end

  private

  def logo_path
    Wagons.find_wagon(__FILE__).root.join("app", "assets", "images", "logo.png")
  end

  def from_page_top(offset) = bounds.top + page.margins[:top] - offset

  def t(key) = I18n.t("participations.attendance_confirmation.#{key}")
end
