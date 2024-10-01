# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Export::Pdf::Participations::KeyDataSheet::Sections::Title < Export::Pdf::Section
  def render
    pdf.move_down(5.mm)

    text(t("year_title", year: Time.zone.now.year), style: :bold)

    pdf.move_down(10.mm)

    text(t("title"), style: :bold)

    pdf.move_down(5.mm)

    text(t("greeting", name: model.person.first_name))
  end

  def t(key, options = {})
    I18n.t("participations.key_data_sheet.#{key}", **options)
  end
end
