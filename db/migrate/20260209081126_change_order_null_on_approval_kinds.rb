# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class ChangeOrderNullOnApprovalKinds < ActiveRecord::Migration[8.0]
  def change
    change_column_null :event_approval_kinds, :order, false
  end
end
