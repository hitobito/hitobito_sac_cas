# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Passes::Sections::Logo < Export::Pdf::Section

  LOGO_BOX_HEIGHT = 130.freeze
  LOGO = 'logo.png'.freeze

  def render
    render_logo
  end

  def render_logo(width: pdf.bounds.width, height: LOGO_BOX_HEIGHT)
    bounding_box([0, cursor], width: width, height: height) do
      image(logo_path, { position: :right, at: [height, height + 20] })
    end
  end

  def logo_path
    image_path(LOGO)
  end

  def image_path(name)
    Wagons.find_wagon(__FILE__).root.join('app', 'assets', 'images', name)
  end

end
