class AddExternalInvoicesToServiceTokens < ActiveRecord::Migration[6.1]
  def change
    add_column :service_tokens, :external_invoices, :boolean
  end
end
