# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Wizards::Steps::Signup::Sektion::VariousFieldsHelper
  def entry_date_text
    case Time.zone.today.month
    when 1..6
      I18n.t("first_period_info", scope: "wizards.steps.signup.sektion.various_fields")
    when 7..9
      I18n.t("second_period_info", scope: "wizards.steps.signup.sektion.various_fields")
    when 10..12
      I18n.t("third_period_info", scope: "wizards.steps.signup.sektion.various_fields")
    end
  end
end
