# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CreateEventReports < ActiveRecord::Migration[8.0]
  def change
    create_table :event_reports do |t|
      t.belongs_to :event, null: false
      t.text :review
      t.text :remarks
      t.datetime :submitted_at
      t.belongs_to :submitter
      t.datetime :approved_at
      t.belongs_to :approver
      t.datetime :paid_at
      t.belongs_to :payer
      t.timestamps
      t.belongs_to :creator, null: false
      t.belongs_to :updater, null: false
    end

    create_table :event_costs do |t|
      t.belongs_to :report, null: false
      t.text :description, null: false
      t.decimal :count, precision: 5, scale: 2, null: false
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.boolean :income, null: false, default: true
    end

    create_table :event_cost_receipts do |t|
      t.belongs_to :report, null: false
      t.text :description, null: false
    end
  end
end
