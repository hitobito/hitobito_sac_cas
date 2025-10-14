#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards
  module Steps
    module SwitchStammsektion
      class Summary < Step
        def info_text
          key = wizard.choose_sektion.group.decorate.membership_admission_through_gs? ?
                "info_text_no_confirmation" :
                "info_text"

          I18n.t(key, scope: "wizards.steps.switch_stammsektion.summary",
            sektion: wizard.choose_sektion.group.name,
            # rubocop:todo Layout/LineLength
            beitragskategorie: I18n.t("roles.beitragskategorie.#{wizard.person.sac_membership.stammsektion_role.beitragskategorie}"))
          # rubocop:enable Layout/LineLength
        end
      end
    end
  end
end
