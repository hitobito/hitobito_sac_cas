# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Dropdown::SacCasExports < Dropdown::Base
  attr_reader :group

  def initialize(template, group)
    super(template, translate(:button), :download)
    @group = group
    init_items
  end

  private

  def init_items
    add_sac_statistics_item
    add_sac_courses_item
    add_alps_recipients
  end

  def add_sac_statistics_item
    add_item_with_popover(
      translate(:sac_statistics),
      template.render(
        "people/export/popover_period",
        model: People::Export::PeriodForm.new(group: group),
        url: template.group_export_sac_statistics_path(group),
        info: translate(:sac_statistics_info)
      )
    )
  end

  def add_sac_courses_item
    add_item_with_popover(
      translate(:sac_courses),
      template.render(
        "groups/popover_year",
        url: template.group_export_sac_courses_path(group)
      )
    )
  end

  def add_alps_recipients
    add_item_with_popover(
      translate(:alps_recipients),
      template.render(
        "groups/popover_alps_recipients",
        model: People::Export::AlpsRecipientsForm.new,
        group: group
      )
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
