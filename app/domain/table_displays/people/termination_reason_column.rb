# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class TerminationReasonColumn < TerminationColumn
    def required_model_includes(attr)
      super + [roles_unscoped: {termination_reason: :translations}]
    end

    def value(terminated_role)
      terminated_role.termination_reason_text
    end
  end
end
