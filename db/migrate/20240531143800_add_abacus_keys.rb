# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddAbacusKeys < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :abacus_subject_key, :integer
    add_column :invoices, :abacus_sales_order_key, :integer
    add_column :invoices, :invoice_kind, :string
    add_column :invoices, :sac_membership_year, :integer
    add_column :invoices, :event_participation_id, :integer
    add_index :invoices, :event_participation_id
  end
end
