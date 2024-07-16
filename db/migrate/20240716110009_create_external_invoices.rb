class CreateExternalInvoices < ActiveRecord::Migration[6.1]
  def change
    create_table :external_invoices do |t|
      t.belongs_to :person, null: false, index: true
      t.string :type, null: false
      t.string :state, null: false, default: 'draft'
      t.date :issued_at
      t.date :sent_at
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0.0
      t.belongs_to :link, polymorphic: true, index: true, null: true
      t.integer :year
      t.integer :abacus_sales_order_key
      t.timestamps
    end

    remove_column :invoices, :abacus_sales_order_key, :integer
    remove_column :invoices, :invoice_kind, :string
    remove_column :invoices, :sac_membership_year, :integer
    remove_column :invoices, :event_participation_id, :integer
  end
end
