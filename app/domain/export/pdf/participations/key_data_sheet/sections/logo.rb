# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::KeyDataSheet::Sections::Logo < Export::Pdf::Section
  LOGO_WIDTH = 170
  LOGO_HEIGHT = 71

  def render
    render_logo
  end

  def render_logo
    float do
      # logo is algined right and the text is matched with the first line of the text
      image(logo_path, at: [pdf.bounds.right - LOGO_WIDTH, pdf.bounds.top + 7], width: LOGO_WIDTH,
        height: LOGO_HEIGHT)
    end
  end

  def logo_path
    logo_lang = if [:it, :de, :fr].include?(I18n.locale)
      I18n.locale
    else
      :de
    end
    logo = "pdf/sac_logo_cmyk_#{logo_lang}_pos.opti.jpg"

    image_path(logo)
  end

  def image_path(name)
    Wagons.find_wagon(__FILE__).root.join("app", "assets", "images", name)
  end
end
