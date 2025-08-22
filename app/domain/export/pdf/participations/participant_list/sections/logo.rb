# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::ParticipantList::Sections::Logo < Export::Pdf::Section
  LOGO_WIDTH = 170
  LOGO_HEIGHT = 71

  def render
    float do
      image(logo_path,
        at: [pdf.bounds.right - LOGO_WIDTH, pdf.bounds.top],
        width: LOGO_WIDTH,
        height: LOGO_HEIGHT)
    end
  end

  def logo_path
    image_path("pdf/sac_logo_cmyk_#{logo_lang}_pos.opti.jpg")
  end

  def logo_lang
    if [:it, :de, :fr].include?(I18n.locale)
      I18n.locale
    else
      :de
    end
  end

  def image_path(name)
    Wagons.find_wagon(__FILE__).root.join("app", "assets", "images", name)
  end
end
