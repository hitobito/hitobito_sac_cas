# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Passes::Membership
  class Header < Export::Pdf::Section

    def render
      pdf.move_down(20)
      text(title, size: 30, style: :bold, align: :center)
      pdf.move_down(10)
      render_sac_info
    end

    private

    def title
      "#{I18n.t('passes.membership.title')} #{Time.zone.today.year}"
    end

    def render_sac_info
      info = ['info@sac-cas.ch', 'www.sac-cas.ch'].join(' - ')
      text(info, align: :center)
    end

  end
end
