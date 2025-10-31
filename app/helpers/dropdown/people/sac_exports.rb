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
    add_jubilare_item
    add_csv_mitglieder_item
    @items.sort_by!(&:label)
  end

  def add_jubilare_item
    add_item_with_popover(
      translate(:jubilare),
      template.render(
        "people/export/popover_jubilare",
        model: People::Export::JubilareForm.new(group: group)
      )
    )
  end

  def add_csv_mitglieder_item
    add_item(
      translate(:csv_mitglieder),
      template.group_people_export_mitglieder_csv_path(group.id, format: :csv),
      method: :post
    )
  end

  def add_item_with_popover(label, content)
    add_item(label, "javascript:void(0)",
      "data-bs-toggle": "popover",
      "data-anchor": "##{id}",
      "data-bs-title": label,
      "data-bs-placement": :bottom,
      "data-bs-content": content)
  end
end
