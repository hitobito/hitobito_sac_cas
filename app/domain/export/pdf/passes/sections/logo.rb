# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Passes::Sections::Logo < Export::Pdf::Section
  def render
    render_logo
  end

  def render_logo
    float do
      image(logo_path, at: [141.208, 190.542], width: 143.579, height: 59.957)
    end
  end

  def logo_path
    logo_lang = if [:it, :de, :fr].include?(I18n.locale)
      I18n.locale
    else
      :de
    end
    logo = "membership_pass/sac_logo_cmyk_#{logo_lang}_pos.opti.jpg"

    image_path(logo)
  end

  def image_path(name)
    Wagons.find_wagon(__FILE__).root.join("app", "assets", "images", name)
  end
end
