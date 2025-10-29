# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Dropdown::People::SacExports < Dropdown::Base
  attr_reader :group

  def initialize(template, group)
    super(template, translate(:button), :download)
    @group = group
    init_items
  end

  private

  def init_items
    add_csv_mitglieder_item
    @items.sort_by!(&:label)
  end

  def add_csv_mitglieder_item
    add_item(
      translate(:csv_mitglieder),
      template.group_people_export_mitglieder_csv_path(group.id, format: :csv),
      method: :post
    )
  end
end
