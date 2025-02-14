class AddLinkExternalSiteToEvent < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :link_external_site, :string
  end
end
