class AddInternalKeyToMailingLists < ActiveRecord::Migration[6.1]
  def change
    # This attribute is used to identify the SAC newsletter mailing list
    # independent of `id` and `name` attributes. This is necessary for reliably
    # identify the record during (repeated) seeding.
    add_column :mailing_lists, :internal_key, :string
  end
end
