# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Passes::Membership
  class Footer < Export::Pdf::Section

    def render
      pdf.move_down(50)
      image(sponsors_image_path, align: :center)
    end

    private

    def sponsors_image_path
      image_path('sponsors_membership_pass.png')
    end

    def image_path(name)
      Wagons.find_wagon(__FILE__).root.join('app', 'assets', 'images', name)
    end

    def t(key)
      I18n.t("passes.membership.#{key}")
    end

  end
end
