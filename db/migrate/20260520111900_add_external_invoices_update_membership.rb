# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddExternalInvoicesUpdateMembership < ActiveRecord::Migration[8.0]

  def change
    add_column :external_invoices, :update_membership, :boolean, default: true, null: false
  end

end
