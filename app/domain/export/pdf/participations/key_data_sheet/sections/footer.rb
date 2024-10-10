# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::KeyDataSheet::Sections::Footer < Export::Pdf::Section
  FONT_SIZE = 7
  POSITION = [0, -10]
  HEIGHT = 8

  def render
    pdf.font_size = FONT_SIZE

    bounding_box(POSITION, width: bounds.width, height: HEIGHT) do
      text(I18n.t("participations.key_data_sheet.footer"))
    end
  end
end
