# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Sheet
  class Event::ApprovalCommissionResponsibility < Sheet::Base
    self.parent_sheet = Sheet::Group

    def title
      I18n.t("event.approval_commission_responsibilities.form.title")
    end
  end
end
