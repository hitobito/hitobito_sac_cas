# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::AttendanceConfirmation::Sections::Footer < Export::Pdf::Section
  FONT_SIZE = 8
  LEADING = 3
  TOP = 775.3
  HEIGHT = 50

  def render
    pdf.font_size(FONT_SIZE) do
      bounding_box([0, from_page_top(TOP)], width: bounds.width, height: HEIGHT) do
        text(SacAddressPresenter.new.format(:attendance_confirmation), inline_format: true,
          leading: LEADING)
        text(place_and_date, align: :right, leading: LEADING)
      end
    end
  end

  private

  def from_page_top(offset) = bounds.top + page.margins[:top] - offset

  def place_and_date
    I18n.t("participations.attendance_confirmation.place_and_date", date: I18n.l(Time.zone.today))
  end
end
